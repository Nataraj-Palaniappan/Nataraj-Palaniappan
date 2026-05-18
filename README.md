## About Branch:
Row Access Policies can be applied to columns in table, allowing specific roles to access specific rows. Eg., a role for region APAC will be able to see only APAC data. It's essentially helpful to maintain all data in a single table, still enabling role based access to data within the table.

Note: Tags Are NOT NEEDED for Row Access Policies. In Snowflake, Row access policies must always be applied directly to a table/view using `ALTER TABLE ... ADD ROW ACCESS POLICY`.
Only for Masking Policies (eg., masking first 6 digits of debit card number or masking few characters in email), Snowflake supports "tag-based masking policies" where you attach a masking policy to a tag, and any column with that tag is automatically masked. 

### So What Are the Tags Useful For in RAP?

In this exercise, the tags serve only as **metadata/documentation** — they label the table/column as "region_controlled" for governance visibility. They do NOT enforce the row access policy. The policy enforcement comes solely from the `ADD ROW ACCESS POLICY` statement.

### $$$ Hi there 👋 - ABOUT ME ### $$$

🔭 Passionate about: Snowflake, Data, Volunteering & Community Service.
📫 Organizations I've worked with: TCS, Coforge, Dataction Analytics.
💬 Ask me about: Career building, Snowflake, How to be successful.

😄 Fun Fact:
      > I have a fighter fish.
      > I prefer non-violence.
