CREATE TABLE [dbo].[vPREmplPeriodsWithoutPay]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[Seq] [smallint] NOT NULL,
[FirstDate] [dbo].[bDate] NOT NULL CONSTRAINT [DF_vPREmplPeriodsWithoutPay_FirstDate] DEFAULT (getdate()),
[LastDate] [dbo].[bDate] NOT NULL CONSTRAINT [DF_vPREmplPeriodsWithoutPay_LastDate] DEFAULT (getdate()),
[Memo] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtPREmplPeriodsWithoutPayd] ON [dbo].[vPREmplPeriodsWithoutPay] FOR DELETE AS

/*-----------------------------------------------------------------
* Created:		EN 4/5/2013 Story 44310 / Task 45407
* Modified:		
*
*	This trigger validates deletions to vPREmplPeriodsWithoutPay.
*	Adds HQ Master Audit entry.
*
*/-----------------------------------------------------------------

IF @@ROWCOUNT = 0 RETURN

/************** Record deletion in HQMA *******************/
SET NOCOUNT ON
-- Do not audit records coming from processing: End Date, PR Group and Pay Seq are NULL 
INSERT INTO dbo.bHQMA  (TableName,	KeyString,	Co,				
						RecType,	FieldName,	OldValue, 
						NewValue,	DateTime,	UserName)
SELECT  'vPREmplPeriodsWithoutPay',	
		'Employee:' + CONVERT(varchar(10),d.Employee) 
		+ 'Seq:' + CONVERT(varchar(10),d.Seq),
		d.PRCo,			
		'D', 
		NULL,			
		NULL, 
		NULL,			
		GETDATE(), 
		SUSER_SNAME()
FROM  deleted d

RETURN

 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtPREmplPeriodsWithoutPayi] ON [dbo].[vPREmplPeriodsWithoutPay] FOR INSERT AS

/*-----------------------------------------------------------------
* Created:  EN 4/5/2013 Story 44310 / Task 45407
* Modified: 
*
*	This trigger validates insertion in vPREmplPeriodsWithoutPay.
*	Validate that LastDate is the same or later than FirstDate.
*	Adds HQ Master Audit entry.
*
*/-----------------------------------------------------------------

DECLARE @errmsg varchar(255), 
		@numrows int, 
		@validcnt int
SELECT @numrows = @@ROWCOUNT
IF @numrows = 0 RETURN
SET NOCOUNT ON

--Validate employee
SELECT @validcnt = COUNT(*) 
FROM bPREH h 
JOIN inserted i ON i.PRCo = h.PRCo AND i.Employee = h.Employee
IF @validcnt <> @numrows
BEGIN
	SELECT @errmsg = 'Invalid Employee'
	GOTO ERROR
END

--Compare order of FirstDate and LastDate
SELECT @validcnt = COUNT(*)
FROM inserted i
WHERE i.FirstDate <= i.LastDate
IF @validcnt <> @numrows
BEGIN
	SELECT @errmsg = 'Last Date cannot be earlier than First Date '
	GOTO ERROR
END

--Verify that date ranges do not intersect or conflict
SET @validcnt = 0

SELECT @validcnt = COUNT(*) 
FROM inserted i
JOIN dbo.vPREmplPeriodsWithoutPay pwp1 ON pwp1.PRCo = i.PRCo AND pwp1.Employee = i.Employee AND pwp1.Seq <> i.Seq
JOIN dbo.vPREmplPeriodsWithoutPay pwp2 ON pwp2.PRCo = i.PRCo AND pwp2.Employee = i.Employee AND pwp2.Seq <> i.Seq
WHERE (
	   i.FirstDate BETWEEN pwp1.FirstDate AND pwp1.LastDate OR
	   i.LastDate BETWEEN pwp1.FirstDate AND pwp1.LastDate
	  )
	  OR
	  (i.FirstDate <= pwp2.FirstDate AND i.LastDate >= pwp2.LastDate)

IF @validcnt <> 0
BEGIN
	SELECT @errmsg = 'Date range conflicts with an existing date range '
	GOTO ERROR
END

/************* Insert HQ Master Audit Entry ***********************************/      
	INSERT INTO dbo.bHQMA  (TableName,	KeyString,	Co,
							RecType,	FieldName,	OldValue,	
							NewValue,	DateTime,	UserName)
	SELECT  'vPREmplPeriodsWithoutPay',	
			'Employee:' + CONVERT(varchar(10),i.Employee) 
			+ 'Seq:' + CONVERT(varchar(10),i.Seq),
			i.PRCo,			
			'A', 
			NULL,			
			NULL, 
			NULL,			
			GETDATE(), 
			SUSER_SNAME()
	FROM inserted i
	JOIN dbo.bPRCO a ON i.PRCo = a.PRCo
	WHERE a.AuditEmployees = 'Y'

RETURN
ERROR:
	SELECT @errmsg = ISNULL(@errmsg,'') + ' - cannot insert PR Employee Period(s) Without Pay!'
   	RAISERROR(@errmsg, 11, -1);
   	ROLLBACK TRANSACTION
   
   
   
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtPREmplPeriodsWithoutPayu] ON [dbo].[vPREmplPeriodsWithoutPay] FOR UPDATE AS

/*-----------------------------------------------------------------
* Created:  EN  EN 4/5/2013 Story 44310 / Task 45407
* Modified:	DAN SO 04/23/2013 - Task 45407 - Wrapped FirstDate and LastDate in "dbo.vfToString("
*
*	This trigger validates update to vPREmplPeriodsWithoutPay.
*	Validate that LastDate is the same or later than FirstDate.
*	Adds HQ Master Audit entries.
*	
*/-----------------------------------------------------------------
    
DECLARE @errmsg varchar(255), 
		@numrows int, 
		@validcnt int
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

IF UPDATE(Employee)
BEGIN
	SELECT @errmsg = 'Employee cannot be updated, it is a key value '
	GOTO ERROR
END 

--Compare order of FirstDate and LastDate
SELECT @validcnt = COUNT(*)
FROM inserted i
WHERE i.FirstDate <= i.LastDate
IF @validcnt <> @numrows
BEGIN
	SELECT @errmsg = 'Last Date cannot be earlier than First Date '
	GOTO ERROR
END

--Verify that date ranges do not intersect or conflict
SET @validcnt = 0

SELECT @validcnt = COUNT(*) 
FROM inserted i
JOIN dbo.vPREmplPeriodsWithoutPay pwp1 ON pwp1.PRCo = i.PRCo AND pwp1.Employee = i.Employee AND pwp1.Seq <> i.Seq
JOIN dbo.vPREmplPeriodsWithoutPay pwp2 ON pwp2.PRCo = i.PRCo AND pwp2.Employee = i.Employee AND pwp2.Seq <> i.Seq
WHERE (
	   i.FirstDate BETWEEN pwp1.FirstDate AND pwp1.LastDate OR
	   i.LastDate BETWEEN pwp1.FirstDate AND pwp1.LastDate
	  )
	  OR
	  (i.FirstDate <= pwp2.FirstDate AND i.LastDate >= pwp2.LastDate)

IF @validcnt <> 0
BEGIN
	SELECT @errmsg = 'Date range conflicts with an existing date range '
	GOTO ERROR
END


/************* Update HQ Master Audit entry **********************************/
IF EXISTS (SELECT * FROM inserted i JOIN dbo.bPRCO a WITH(NOLOCK) ON a.PRCo = i.PRCo WHERE a.AuditEmployees = 'Y')
BEGIN
	IF UPDATE (FirstDate)
	BEGIN
		INSERT INTO dbo.bHQMA (TableName,	KeyString,	Co,
							   RecType,		FieldName,	OldValue, 
							   NewValue,	DateTime,	UserName)
					   SELECT 'vPREmplPeriodsWithoutPay',
							  'Employee:' + CONVERT(varchar(10),i.Employee) 
							  + 'Seq:' + CONVERT(varchar(10),i.Seq),
							  i.PRCo,			
							  'C', 
							  'FirstDate',			
							  dbo.vfToString(d.FirstDate),
							  dbo.vfToString(i.FirstDate),		
							  GETDATE(), 
							  SUSER_SNAME()
						 FROM inserted i
						 JOIN deleted d 
						 ON	  i.PRCo = d.PRCo 
						      AND i.Employee = d.Employee 
						      AND i.Seq = d.Seq
						WHERE i.FirstDate <> d.FirstDate
	END
	
	IF UPDATE (LastDate)
	BEGIN
		INSERT INTO dbo.bHQMA (TableName,	KeyString,	Co,
							   RecType,		FieldName,	OldValue, 
							   NewValue,	DateTime,	UserName)
					   SELECT 'vPREmplPeriodsWithoutPay',
							  'Employee:' + CONVERT(varchar(10),i.Employee) 
							  + 'Seq:' + CONVERT(varchar(10),i.Seq),
							  i.PRCo,			
							  'C', 
							  'LastDate',			
							  dbo.vfToString(d.LastDate),
							  dbo.vfToString(i.LastDate),
							  GETDATE(), 
							  SUSER_SNAME()
						 FROM inserted i
						 JOIN deleted d 
						 ON	  i.PRCo = d.PRCo 
						      AND i.Employee = d.Employee 
						      AND i.Seq = d.Seq
						WHERE i.LastDate <> d.LastDate
	END

END
     
RETURN 
ERROR:
SELECT @errmsg = ISNULL(@errmsg,'') + ' - cannot update PR Employee Period(s) Without Pay!'
	RAISERROR(@errmsg, 11, -1);
	ROLLBACK TRANSACTION
     
     
     
    
    
    
   
   
   
   
   
   
   
   
   
   
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[vPREmplPeriodsWithoutPay] ADD CONSTRAINT [PK_vPREmplPeriodsWithoutPay_PRCo_Employee_Seq] PRIMARY KEY CLUSTERED  ([PRCo], [Employee], [Seq]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[vPREmplPeriodsWithoutPay] TO [public]
GRANT SELECT ON  [dbo].[vPREmplPeriodsWithoutPay] TO [public]
GRANT INSERT ON  [dbo].[vPREmplPeriodsWithoutPay] TO [public]
GRANT DELETE ON  [dbo].[vPREmplPeriodsWithoutPay] TO [public]
GRANT UPDATE ON  [dbo].[vPREmplPeriodsWithoutPay] TO [public]
GO
