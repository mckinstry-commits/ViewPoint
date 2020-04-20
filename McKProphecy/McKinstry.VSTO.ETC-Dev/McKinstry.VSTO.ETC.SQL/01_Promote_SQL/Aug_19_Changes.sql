--Additions
Action Buttons in Control Panel now dynamically update when Viewpoint loading/processing is ongoing to imporve clarity.
Improved and updated logic and errors displayed when closing and saving the workbook.

--Updates
Update All Column Headers to be more descriptive and better align to user understanding.
All error messages have updated test to improve clarity.
Highlighted color for updated row in Labor and Non-Labor Cost projection to light blue.  (Blank Rate will still display as Red).
Improvement of Logic used to determine Valid Months to Create a Batch.
Remove Contracts ' 99999-' and ' 99998-' From Contract Selection. (These Contracts are for accounting use only)
Granted all Viewpoint Users explicit access to all SQL objects to prevent Permission errors.
Update User security in Staging to allow all users to insert Detailed Cost Projection data.
Viewpoint updated to allow Employee ID Cost Projections for users without Payroll data access.

--Fixes
Fix to database triggers that will allow Revenue Batches to be posted.
Additional Fix to allow Contracts with Blank PRG values to display on the Contract Report
Correct Logic of Total Contract Margin on the Contract Report.  (Was displaying an error for empty Contract Items)
Fixed outdated Staging SQL object for re-projecting the same cost projection month.
Row insert on detailed Cost projection now works correctly with Used Filter enabled.
When inserting a new row in a Cost projection, the varience column will be left blank.
Projection Month now always properly Read-Only on Projections, and editable on Report Pages.
Switching Contracts now deletes all existing sheets after prompt.
