CREATE RULE dbo.brJCStatus AS /* JRE 09/17/96 Job/Contract Status
		1= Open 2=Soft Close 3=Final Close
		9=Job/Contract being purged */
		@VALUE IN (null,0, 1, 2, 3)




