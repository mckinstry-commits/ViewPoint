CREATE TABLE [dbo].[vPRArrears]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[DLCode] [dbo].[bEDLCode] NOT NULL,
[Seq] [smallint] NOT NULL,
[Date] [dbo].[bDate] NOT NULL CONSTRAINT [DF_vPRArrears_Date] DEFAULT (getdate()),
[ArrearsAmt] [dbo].[bDollar] NULL,
[PaybackAmt] [dbo].[bDollar] NULL,
[PRGroup] [dbo].[bGroup] NULL,
[PREndDate] [dbo].[bDate] NULL,
[PaySeq] [tinyint] NULL,
[EDLType] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vPRArrears_EDLType] DEFAULT ('D'),
[PurgeYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vPRArrears_PurgeYN] DEFAULT ('N'),
[Memo] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtPRArrearsd] ON [dbo].[vPRArrears] FOR DELETE AS

/*-----------------------------------------------------------------
* Created:		KK  08/03/2012
* Modified:		CHS	08/30/2012 - B-10148 Modified to allow batch delete
*				KK  09/08/2012 - B-10148/TK-17626 Added end date and pr group to the join statements to get the 
*												  a unique sum for Life to date arrears/payback
*			    KK  09/10/2012 - B-10148/TK-17626 Separated arrears and delete to only update life to date in PRED
*												  if the record set for arrears/payback is not null
*				CHS	08/30/2012 - B-10148 fixed where it wasn't updating correctly
*				CHS 09/12/2012 - B-10148 fixed multiple record errors.
*				KK  09/13/2012 - B-10148 Took out the pr group from the update to account for manual entries
*				KK  09/27/2012 - B-10148/TK-17626 Changed back to update PRED using math, and allowed for batch deletes
*												  to update Life to date values in PRED
*				MV	10/15/2012 - B-10534/TK-18444 Do not update to Life-to-Date fields in bPRED during purge
*				KK  10/23/2012 - D-06062/TK-18676 Only update HQMA on manual entries, NOT when record is created by 
*												  Payroll Processing.
*
*	This trigger validates deletions to vPRArrears (PR Arrears)
*
*	Adds HQ Master Audit entry.
*/-----------------------------------------------------------------

IF @@ROWCOUNT = 0 RETURN

-- validate that the record exists in PRED
IF EXISTS (SELECT * FROM dbo.bPRED ed
					JOIN deleted d
						ON  ed.PRCo = d.PRCo 
						AND ed.Employee = d.Employee
						AND	ed.DLCode = d.DLCode)
BEGIN
	/************** Update record in PRED ******************/
	DECLARE @tblDelete TABLE(prco bCompany,
							 employee bEmployee,
							 dlcode bEDLCode,
							 arrearSum bDollar, 
							 paybackSum bDollar)
	INSERT INTO @tblDelete (prco, employee, dlcode, arrearSum, paybackSum)
	SELECT ed.PRCo,ed.Employee,ed.DLCode,
					   SUM(ArrearsAmt), 
					   SUM(PaybackAmt) 
				FROM deleted d
				JOIN dbo.bPRED ed
					ON  d.PRCo = ed.PRCo
					AND d.Employee = ed.Employee
					AND d.DLCode = ed.DLCode
				WHERE   d.PRCo = ed.PRCo
					AND d.Employee = ed.Employee
					AND d.PurgeYN = 'N'
				GROUP BY ed.DLCode,ed.PRCo,ed.Employee	
	/************** Update record in PRED ******************/
	UPDATE dbo.bPRED SET 
		LifeToDateArrears = ISNULL(LifeToDateArrears,0) - ISNULL(arrearSum,0),
		LifeToDatePayback = ISNULL(LifeToDatePayback,0) - ISNULL(paybackSum,0)		
	FROM @tblDelete up
	JOIN dbo.bPRED ed
		ON  up.prco = ed.PRCo
		AND up.employee = ed.Employee
		AND up.dlcode = ed.DLCode
END	   
/************** Record deletion in HQMA *******************/
SET NOCOUNT ON
-- Do not audit records coming from processing: End Date, PR Group and Pay Seq are NULL 
INSERT INTO dbo.bHQMA  (TableName,		
						KeyString, 
						Co,				
						RecType, 
						FieldName,		
						OldValue, 
						NewValue,		
						DateTime, 
						UserName)
				SELECT  'vPRArrears',	
						'Employee:' + CONVERT(varchar(10),d.Employee) 
						+ 'DLCode:' + CONVERT(varchar(10),d.DLCode) 
						+ 'Seq:' + CONVERT(varchar(10),d.Seq),
						d.PRCo,			
						'D', 
						NULL,			
						NULL, 
						NULL,			
						GETDATE(), 
						SUSER_SNAME()
				FROM  deleted d
				WHERE d.PurgeYN = 'N'
				  AND d.PRGroup IS NULL
				  AND d.PREndDate IS NULL
				  AND d.PaySeq IS NULL
RETURN

 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtPRArrearsi] ON [dbo].[vPRArrears] FOR INSERT AS

/*-----------------------------------------------------------------
* Created:  KK  08/03/2012
* Modified: EN	08/09/2012 - B-10148/TK-16683 Correction to employee validation to include PRCo
*			CHS	08/30/2012 - B-10148 Modified not use math in the PRED update
*			KK  09/08/2012 - B-10148 Modified to join on DLCode
*			KK  09/27/2012 - B-10148/TK-17626 Changed back to insert PRED using math
*			KK  10/23/2012 - D-06062/TK-18676 Only update HQMA on manual entries, NOT when record is created by 
*											  Payroll Processing.
*
*	This trigger validates insertion in vPRArrears (PR Arrears) 
*	Adds entry to PRED for Life to date Arrears/Payback
*	Adds HQ Master Audit entry.
*	'A' Add mode
*/-----------------------------------------------------------------

DECLARE @errmsg varchar(255), 
		@numrows int, 
		@validcnt int, 
		@validcnt2 int
SELECT @numrows = @@rowcount
IF @numrows = 0 RETURN
SET NOCOUNT ON

/************* Insert PRED Life to date values for Arrears/Payback ************/
--validate that the record exists
IF EXISTS(SELECT * FROM dbo.bPRED ed
				   JOIN inserted i
						 ON ed.PRCo = i.PRCo 
						AND ed.Employee = i.Employee 
						AND ed.DLCode = i.DLCode)
BEGIN
	--add the new values to be inserted to the old values 
	UPDATE dbo.bPRED 
		SET LifeToDateArrears = ISNULL(LifeToDateArrears,0) + ISNULL(ArrearsAmt,0),
			LifeToDatePayback = ISNULL(LifeToDatePayback,0) + ISNULL(PaybackAmt,0) 
		FROM inserted i
		JOIN dbo.bPRED ed
			  ON ed.PRCo = i.PRCo 
			 AND ed.Employee = i.Employee 
			 AND ed.DLCode = i.DLCode	
END	

/************* Insert HQ Master Audit Entry ***********************************/      
INSERT INTO dbo.bHQMA  (TableName,		
						KeyString, 
						Co,				
						RecType, 
						FieldName,		
						OldValue, 
						NewValue,		
						DateTime, 
						UserName)
				SELECT  'vPRArrears',	
						'Employee:' + CONVERT(varchar(10),i.Employee) 
						+ 'DLCode:' + CONVERT(varchar(10),i.DLCode) 
						+ 'Seq:' + CONVERT(varchar(10),i.Seq),
						i.PRCo,			
						'A', 
						NULL,			
						NULL, 
						NULL,			
						GETDATE(), 
						SUSER_SNAME()
				FROM inserted i
				WHERE i.PRGroup IS NULL
				  AND i.PREndDate IS NULL
				  AND i.PaySeq IS NULL
RETURN
ERROR:
	SELECT @errmsg = ISNULL(@errmsg,'') + ' - cannot insert PR Deductions and Liabilities!'
   	RAISERROR(@errmsg, 11, -1);
   	ROLLBACK TRANSACTION
   
   
   
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtPRArrearsu] ON [dbo].[vPRArrears] FOR UPDATE AS

/*-----------------------------------------------------------------
* Created:  KK  08/03/2012
* Modified:	CHS	08/30/2012 - B-10148 Modified not use math in the PRED update
*			KK  09/08/2012 - B-10148 Modified to join on DLCode
*			KK  09/27/2012 - B-10148/TK-17626 Changed back to update PRED using math
*			KK  10/23/2012 - D-06062/TK-18676 Only update HQMA on manual entries, NOT when record is created by 
*											  Payroll Processing.
*
*	This trigger validates UPDATEs to vPRArrears (PR Arrears)
*	Modifies the Life to date values in PRED for Arrears/Payback
*	Adds HQ Master Audit entry.
*	'C' Change mode
*/-----------------------------------------------------------------
    
DECLARE @errmsg varchar(255), 
		@numrows int, 
		@validcnt int, 
		@validcnt2 int   
SELECT @numrows = @@rowcount
IF @numrows = 0 RETURN
SET NOCOUNT ON    
    
/************* Validate fields before updating ************/    

--Company and DL Code and Employee are Key fields and cannot update
IF UPDATE(PRCo)
BEGIN
	SELECT @errmsg = 'PR Company cannot be updated, it is a key value '
	GOTO ERROR
END

IF UPDATE(DLCode)
BEGIN
	SELECT @errmsg = 'DLCode cannot be updated, it is a key value '
	GOTO ERROR
END

IF UPDATE(Employee)
BEGIN
	SELECT @errmsg = 'Employee cannot be updated, it is a key value '
	GOTO ERROR
END 

/************* Update PRED Life To Date Arrears and Payback ******************/
--validate that the record exists
IF EXISTS(SELECT * FROM dbo.bPRED ed WITH(NOLOCK)
				   JOIN inserted i
				    ON  ed.PRCo = i.PRCo 
				    AND ed.Employee = i.Employee 
				    AND ed.DLCode = i.DLCode)
BEGIN
	IF UPDATE (ArrearsAmt)
	BEGIN
		--delete old values compute new values add the new values to be inserted to the old values 
		UPDATE dbo.bPRED 
		 SET LifeToDateArrears = (ISNULL(LifeToDateArrears,0) - ISNULL(d.ArrearsAmt,0)) + ISNULL(i.ArrearsAmt,0)					
			FROM inserted i
			JOIN deleted d
				 ON  i.DLCode = d.DLCode 
				 AND i.PRCo = d.PRCo
				 AND i.Employee = d.Employee 
				 AND i.Seq = d.Seq
			JOIN dbo.bPRED e
				 ON  e.PRCo = i.PRCo 
				 AND e.Employee = i.Employee 
				 AND e.DLCode = i.DLCode
	END
	
	IF UPDATE (PaybackAmt)
	BEGIN
		--delete old values compute new values add the new values to be inserted to the old values 
		UPDATE dbo.bPRED
		 SET LifeToDatePayback = (ISNULL(LifeToDatePayback,0) - ISNULL(d.PaybackAmt,0)) + ISNULL(i.PaybackAmt,0)					
			FROM inserted i
			JOIN deleted d
				 ON  i.DLCode = d.DLCode 
				 AND i.PRCo = d.PRCo
				 AND i.Employee = d.Employee 
				 AND i.Seq = d.Seq
			JOIN dbo.bPRED e
				 ON  e.PRCo = i.PRCo 
				 AND e.Employee = i.Employee 
				 AND e.DLCode = i.DLCode
	END
END

/************* Update HQ Master Audit entry **********************************/
IF EXISTS (SELECT * FROM inserted i JOIN dbo.bPRCO a WITH(NOLOCK) ON a.PRCo = i.PRCo WHERE a.AuditDLs = 'Y')
BEGIN
	IF UPDATE (Date)
	BEGIN
		INSERT INTO dbo.bHQMA (TableName,		
							   KeyString,
							   Co,
							   RecType,
							   FieldName,		
							   OldValue, 
							   NewValue,		
							   DateTime, 
							   UserName)
					   SELECT 'vPRArrears',
							  'Employee:' + CONVERT(varchar(10),i.Employee) 
							  + 'DLCode:' + CONVERT(varchar(10),i.DLCode) 
							  + 'Seq:' + CONVERT(varchar(10),i.Seq),
							  i.PRCo,			
							  'C', 
							  'Date',			
							  CONVERT(varchar(10),d.Date), 
							  CONVERT(varchar(10),i.Date),			
							  GETDATE(), 
							  SUSER_SNAME()
						 FROM inserted i
						 JOIN deleted d 
						   ON i.DLCode = d.DLCode 
						      AND i.PRCo = d.PRCo 
						      AND i.Employee = d.Employee 
						      AND i.Seq = d.Seq
						WHERE i.Date <> d.Date
							  AND i.PRGroup IS NULL
							  AND i.PREndDate IS NULL
							  AND i.PaySeq IS NULL
	END
	
	IF UPDATE (ArrearsAmt)
	BEGIN
		INSERT INTO dbo.bHQMA (TableName,		
							   KeyString, 
							   Co,				
							   RecType, 
							   FieldName,		
							   OldValue, 
							   NewValue,		
							   DateTime, 
							   UserName)
					   SELECT 'vPRArrears',	
							  'Employee:' + CONVERT(varchar(10),i.Employee) 
							  + 'DLCode:' + CONVERT(varchar(10),i.DLCode) 
							  + 'Seq:' + CONVERT(varchar(10),i.Seq),
							  i.PRCo,			
							  'C', 
							  'ArrearsAmt',			
							  CONVERT(varchar(30),d.ArrearsAmt), 
							  CONVERT(varchar(30),i.ArrearsAmt),			
							  GETDATE(), 
							  SUSER_SNAME()
						 FROM inserted i
						 JOIN deleted d 
						   ON i.DLCode = d.DLCode 
						      AND i.PRCo = d.PRCo 
						      AND i.Employee = d.Employee 
						      AND i.Seq = d.Seq
					    WHERE i.ArrearsAmt <> d.ArrearsAmt
							  AND i.PRGroup IS NULL
							  AND i.PREndDate IS NULL
							  AND i.PaySeq IS NULL
	END
	
	IF UPDATE (PaybackAmt)
	BEGIN
		INSERT INTO dbo.bHQMA (TableName,		
							   KeyString, 
							   Co,				
							   RecType, 
							   FieldName,		
							   OldValue, 
							   NewValue,		
							   DateTime, 
							   UserName)
					   SELECT 'vPRArrears',	
							  'Employee:' + CONVERT(varchar(10),i.Employee) 
							  + 'DLCode:' + CONVERT(varchar(10),i.DLCode) 
							  + 'Seq:' + CONVERT(varchar(10),i.Seq),
							  i.PRCo,			
							  'C', 
							  'PaybackAmt',			
							  CONVERT(varchar(30),d.PaybackAmt), 
							  CONVERT(varchar(30),i.PaybackAmt),			
							  GETDATE(), 
							  SUSER_SNAME()
					     FROM inserted i
						 JOIN deleted d 
						   ON i.DLCode = d.DLCode 
						      AND i.PRCo = d.PRCo 
						      AND i.Employee = d.Employee 
						      AND i.Seq = d.Seq
					    WHERE i.PaybackAmt <> d.PaybackAmt
							  AND i.PRGroup IS NULL
							  AND i.PREndDate IS NULL
							  AND i.PaySeq IS NULL
	END

END
     
RETURN 
ERROR:
SELECT @errmsg = ISNULL(@errmsg,'') + ' - cannot UPDATE PR Deductions AND Liabilities!'
	RAISERROR(@errmsg, 11, -1);
	ROLLBACK TRANSACTION
     
     
     
    
    
    
   
   
   
   
   
   
   
   
   
   
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[vPRArrears] ADD CONSTRAINT [PK_vPRArrears_PRCo_Employee_DLCode_Seq] PRIMARY KEY CLUSTERED  ([PRCo], [Employee], [DLCode], [Seq]) ON [PRIMARY]
GO
