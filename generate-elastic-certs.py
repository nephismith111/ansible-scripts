#!/usr/bin/env python3

import os
import sys
import subprocess
import json
import ipaddress

###############################################################################
# Configuration (defaults)
###############################################################################
DEFAULT_VAULT_ADDR = os.environ.get("VAULT_ADDR", "https://192.168.86.21:8200")
PKI_ENGINE = "pki-root-ca"
ROLE_NAME = "generic"
TTL = "8760h"  # 1 year
CERTS_BASE_DIR = "./elastic-certs"

# Simple color codes (optional)
RED = "\033[0;31m"
GREEN = "\033[0;32m"
YELLOW = "\033[1;33m"
NC = "\033[0m"  # No Color


###############################################################################
# Helpers
###############################################################################

def is_vault_installed():
    """Check if the 'vault' CLI is in the PATH."""
    from shutil import which
    return which("vault") is not None


def validate_ip(ip_str):
    """Return True if 'ip_str' is a valid IPv4 address, else False."""
    try:
        # If you only allow IPv4, enforce version=4:
        ipaddress.IPv4Address(ip_str)
        return True
    except ValueError:
        return False


def read_multiline(prompt, validate_fn=None):
    """
    Prompt for multiple lines until blank line is entered.
    Returns comma-separated values of all lines entered.

    If 'validate_fn' is provided, each line is passed to it:
      - Lines failing validation are skipped with an error message.
    """
    print(prompt)
    lines = []
    while True:
        user_input = input("> ").strip()
        if not user_input:
            break  # blank line -> done

        if validate_fn and not validate_fn(user_input):
            print(f"{RED}Invalid entry: {user_input}{NC}")
            continue

        lines.append(user_input)
    return ",".join(lines)


def chmod600(path):
    """Set file permissions to 600 (owner RW) if possible."""
    try:
        os.chmod(path, 0o600)
    except OSError as e:
        print(f"{RED}Warning: failed to chmod 600 on {path}: {e}{NC}")


###############################################################################
# Main
###############################################################################

def main():
    # 1. Ensure Vault is installed
    if not is_vault_installed():
        print(f"{RED}Error: 'vault' command not found in PATH{NC}")
        sys.exit(1)

    # 2. Prompt for common_name
    while True:
        common_name = input(
            f"{YELLOW}Enter the common name (e.g., ns-elastic-01.local):{NC}\n> "
        ).strip()
        if common_name:
            break
        print(f"{RED}Common name cannot be empty{NC}")

    # 3. Prompt for short name (must be http or transport)
    while True:
        short_name = input(
            f"{YELLOW}Enter a short name for the certificate type (http or transport):{NC}\n> "
        ).strip()
        if short_name in ("http", "transport"):
            break
        print(f"{RED}Short name must be either 'http' or 'transport'{NC}")

    # 4. Collect IP SANs
    ip_sans = read_multiline(
        f"{YELLOW}Collecting IP SANs (one per line, empty line to finish):{NC}",
        validate_fn=validate_ip
    )

    # 5. Collect DNS SANs
    sans = read_multiline(
        f"{YELLOW}Collecting DNS SANs (one per line, empty line to finish):{NC}"
    )

    # 6. Create an output directory
    cert_dir = os.path.join(CERTS_BASE_DIR, common_name)
    os.makedirs(cert_dir, exist_ok=True)

    # 7. Generate certificates using 'vault' CLI
    print(f"{GREEN}Generating certificates...{NC}")
    print(f"{YELLOW}Executing Vault command:{NC}")
    print(
        f"vault write -format=json {PKI_ENGINE}/issue/{ROLE_NAME} \\\n"
        f"  common_name=\"{common_name}\" \\\n"
        f"  alt_names=\"{sans}\" \\\n"
        f"  ip_sans=\"{ip_sans}\" \\\n"
        f"  ttl=\"{TTL}\""
    )

    try:
        result = subprocess.run(
            [
                "vault", "write", "-format=json",
                f"{PKI_ENGINE}/issue/{ROLE_NAME}",
                f"common_name={common_name}",
                f"alt_names={sans}",
                f"ip_sans={ip_sans}",
                f"ttl={TTL}",
            ],
            capture_output=True,
            text=True,
            check=False,
        )
    except OSError as e:
        print(f"{RED}Failed to run vault CLI: {e}{NC}")
        sys.exit(1)

    if result.returncode != 0:
        print(
            f"{RED}Error writing data to {PKI_ENGINE}/issue/{ROLE_NAME}:\n"
            f"{result.stderr}{NC}"
        )
        print(f"{RED}Certificate generation failed{NC}")
        sys.exit(1)

    # 8. Parse JSON for certificate data
    try:
        cert_data = json.loads(result.stdout)
    except json.JSONDecodeError as e:
        print(f"{RED}Failed to parse JSON output from vault: {e}{NC}")
        sys.exit(1)

    # 9. Write out private_key, certificate, issuing_ca, chain
    key_path = os.path.join(cert_dir, f"{short_name}.key")
    cert_path = os.path.join(cert_dir, f"{short_name}.pem")
    ca_path = os.path.join(cert_dir, f"{short_name}-ca.pem")
    chain_path = os.path.join(cert_dir, f"{short_name}-chain.pem")

    try:
        with open(key_path, "w") as f:
            f.write(cert_data["data"].get("private_key", ""))

        with open(cert_path, "w") as f:
            f.write(cert_data["data"].get("certificate", ""))

        with open(ca_path, "w") as f:
            f.write(cert_data["data"].get("issuing_ca", ""))

        with open(chain_path, "w") as f:
            # The chain can be an array of certs
            chain_list = cert_data["data"].get("ca_chain", [])
            f.write("\n".join(chain_list))
    except OSError as e:
        print(f"{RED}Failed to write certificates: {e}{NC}")
        sys.exit(1)

    # 10. Set file permissions to 600
    chmod600(key_path)
    chmod600(cert_path)
    chmod600(ca_path)
    chmod600(chain_path)

    # 11. Report success
    print(f"{GREEN}Certificates generated successfully in {cert_dir}{NC}")
    print(f"{GREEN}Files generated:{NC}")
    try:
        os.system(f"ls -l '{cert_dir}'")
    except Exception:
        pass  # fallback: ignore any errors from 'ls -l'


if __name__ == "__main__":
    main()
