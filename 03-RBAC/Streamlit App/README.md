# RBAC Lab - User Onboarding App

**Author:** NATARAJ_PALANIAPPAN

A Streamlit app for automating Snowflake RBAC user onboarding/offboarding.

## Features

| Tab | Action |
|-----|--------|
| Onboard User | Grant a functional role (Analyst/Engineer/DBA) to a user |
| Offboard User | Revoke a functional role from a user |
| Audit Roles | List all users assigned to a specific role |

## File Structure

| File | Purpose |
|------|---------|
| `snowflake.yml` | App config — tells Snowflake the entry file, artifacts, and warehouse |
| `pyproject.toml` | Python dependencies (streamlit[snowflake]) |
| `.streamlit/config.toml` | UI theme (optional) |
| `streamlit_app.py` | App logic — UI + SQL for grant/revoke/audit |

## Prerequisites

- The RBAC_LAB roles must exist (run the main lab SQL first)
- The app must run under a role with `MANAGE GRANTS` or ownership of the lab roles

## Usage

1. Upload this folder to a Snowflake Workspace
2. Set the app role to `RBAC_LAB_OWNER` in App Settings
3. Click **Run**
