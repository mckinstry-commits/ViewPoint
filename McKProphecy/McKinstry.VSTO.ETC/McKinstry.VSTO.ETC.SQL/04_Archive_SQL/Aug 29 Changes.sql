--Additions
Manual ETC Entry columns now only allow entry of Hours and Rate for Labor Cost Types, and Total Cost for Non-Labor. Non-Entry fields are set greyed out.
Control Sheet of Workbook now displays "Prophecy Dev" or "Viewpoint Staging" when using those environments. 
The Excel file is available as a Report from within Viewpoint Staging.  Look for "McKinstry Projections" in "All Reports", or "3-Proj. Financials/Job Cost"
The tool now sets a default print area for better printing of data from the tool.
The tool now checks if text values have been entered in number fields, and displays an error while saving.
Added warning message on the Revenue tab when the user has used the Margin Seek column, to remind them that they need to update their cost projection.
Added warning message on the Cost Projection Summary when saving a Manual ETC value that results in a Projected Final Cost that is less than Actual Cost.


--Updates
Saving a local copy of a report and opening it later allows the user to view all data in grouped columns without errors.
Cost Type now includes the number for sorting on the Project Report.
The Excel File has been renamed "McKinstry Projections.xltx", and is now located in a new folder in the Staging Environment.
Some field descriptions that were too long to display properly have been converted to Comments.
When a user encounters an error when building a worksheet, the tool will now revert back to the state before the error was encountered.  Partially formed workbooks were causing other errors.
Increased the width of some columns to account for larger projects.


--Fixes
Inserted row on Labor and Non-Labor tab were corrected to be highlighted blue.
Project report will no longer produce an error if no Phase Codes are mapped to the project, first grouped table will be empty.
Fixed an erro that caused the "Get Contracts and Projects" button to get stuck as "Processing"
Workbook render has been turned off during batch posting to prevent partially updated workbook from appearing.
After Posting a batch, the Create Batch button now reappears correctly.
Fixed an issue that was causing too many columns to be highlighted as yellow for some contracts.
The control Tab will no longer show the same project multiples times after posting a cost batch.
