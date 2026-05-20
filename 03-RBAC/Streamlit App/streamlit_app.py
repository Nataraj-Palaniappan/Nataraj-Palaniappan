import os
import streamlit as st

st.set_page_config(page_title="RBAC Lab - User Onboarding", page_icon="\u2699\ufe0f", layout="wide")

conn = st.connection("snowflake", ttl=os.getenv("SNOWFLAKE_CONNECTION_TTL"))
session = conn.session()

st.title("RBAC Lab - User Onboarding")
st.caption("Author: NATARAJ_PALANIAPPAN")

ROLE_MAP = {
    "Analyst": "RBAC_LAB_ANALYST",
    "Engineer": "RBAC_LAB_ENGINEER",
    "DBA": "RBAC_LAB_DBA"
}

ROLE_DESCRIPTIONS = {
    "Analyst": "READ access (SELECT on all tables/views)",
    "Engineer": "READ + WRITE access (SELECT, INSERT, UPDATE, DELETE)",
    "DBA": "READ + WRITE + ADMIN access (full DDL + DML)",
}

tab_onboard, tab_offboard, tab_audit = st.tabs(["Onboard User", "Offboard User", "Audit Roles"])

with tab_onboard:
    st.subheader("Onboard a New User")
    col1, col2 = st.columns(2)
    with col1:
        onboard_username = st.text_input("Username", placeholder="e.g. JOHN_SMITH", key="onboard_user")
    with col2:
        onboard_role = st.selectbox("Role Type", options=list(ROLE_MAP.keys()), key="onboard_role")

    st.info(f"**{onboard_role}** grants: {ROLE_DESCRIPTIONS[onboard_role]}")

    if st.button("Onboard User", type="primary", key="btn_onboard"):
        if not onboard_username.strip():
            st.error("Please enter a username.")
        else:
            username = onboard_username.strip().upper()
            functional_role = ROLE_MAP[onboard_role]
            try:
                session.sql(f"GRANT ROLE {functional_role} TO USER {username}").collect()
                st.success(f"User **{username}** onboarded as **{onboard_role}** (granted role `{functional_role}`).")
            except Exception as e:
                st.error(f"Failed to onboard user: {e}")

with tab_offboard:
    st.subheader("Offboard a User")
    col1, col2 = st.columns(2)
    with col1:
        offboard_username = st.text_input("Username", placeholder="e.g. NATARAJ", key="offboard_user")
    with col2:
        offboard_role = st.selectbox("Role Type", options=list(ROLE_MAP.keys()), key="offboard_role")

    if st.button("Offboard User", type="primary", key="btn_offboard"):
        if not offboard_username.strip():
            st.error("Please enter a username.")
        else:
            username = offboard_username.strip().upper()
            functional_role = ROLE_MAP[offboard_role]
            try:
                session.sql(f"REVOKE ROLE {functional_role} FROM USER {username}").collect()
                st.success(f"User **{username}** offboarded from **{offboard_role}** (revoked role `{functional_role}`).")
            except Exception as e:
                st.error(f"Failed to offboard user: {e}")

with tab_audit:
    st.subheader("View Role Members")
    audit_role = st.selectbox("Select Role", options=list(ROLE_MAP.keys()), key="audit_role")

    if st.button("Show Members", key="btn_audit"):
        functional_role = ROLE_MAP[audit_role]
        try:
            session.sql(f"SHOW GRANTS OF ROLE {functional_role}").collect()
            df = session.sql(
                """SELECT "grantee_name" AS USERNAME,
                          "role" AS ROLE_GRANTED,
                          "granted_by" AS GRANTED_BY,
                          "created_on" AS GRANTED_ON
                   FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
                   WHERE "granted_to" = 'USER'"""
            ).to_pandas()

            if df.empty:
                st.warning(f"No users currently have the **{audit_role}** role.")
            else:
                st.dataframe(df, use_container_width=True)
                st.metric("Total Members", len(df))
        except Exception as e:
            st.error(f"Failed to list members: {e}")
