CREATE TABLE [dbo].[vPRROEEmployeeInsurEarningsPPD]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[PRCo] [dbo].[bCompany] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[ROEDate] [dbo].[bDate] NOT NULL,
[PayPeriodEndingDate] [dbo].[bDate] NOT NULL,
[InsurableEarnings] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPRROEEmployeeInsurEarningsPPD_InsurableEarnings] DEFAULT ((0))
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[vtPRROEEmployeeInsurEarningsPPDd] 
   ON  [dbo].[vPRROEEmployeeInsurEarningsPPD] 
   FOR DELETE AS 
/*-----------------------------------------------------------------
* Created:		MV	02/19/2013  TFS#40979 PR ROE 
* Modified:		
*
*	Delete trigger for PR ROE Employee InsurEarningsPPD
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vPRROEEmployeeInsurEarningsPPD', 
	'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) 
		+ ', Employee: ' + CAST(d.Employee AS VARCHAR(10))
		+ ', ROEDate: ' + CAST(d.ROEDate AS varchar(10))
		+ ', PayPeriodEndingDate: ' + CAST(d.PayPeriodEndingDate AS VARCHAR(10)),  
	d.PRCo, 
	'D', 
	NULL, 
	NULL, 
	NULL, 
	GETDATE(), 
	SUSER_SNAME() 
FROM DELETED d

	
RETURN




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtPRROEEmployeeInsurEarningsPPDi] 
	ON [dbo].[vPRROEEmployeeInsurEarningsPPD] 
	FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		MV	02/19/2013  TFS#40979 PR ROE 
* Modified:		
*
*	Insert trigger for PR ROE Employee InsurEarningsPPD
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* add HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vPRROEEmployeeInsurEarningsPPD', 
	'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10))
		+ ', PayPeriodEndingDate: ' + CAST(i.PayPeriodEndingDate AS VARCHAR(10)),  
	i.PRCo, 
	'A', 
	NULL, 
	NULL, 
	NULL, 
	GETDATE(), 
	SUSER_SNAME() 
FROM inserted i
  
RETURN
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtPRROEEmployeeInsurEarningsPPDu] 
   ON  [dbo].[vPRROEEmployeeInsurEarningsPPD] 
   FOR UPDATE AS 
/*-----------------------------------------------------------------
* Created:		MV	02/19/2013 TFS#40979 PR ROE
* Modified: 
*
*	Update trigger for PR ROE Employee InsurEarningsPPD
*	Constraints are handled by Foreign Keys, and Unique Index (see those before adding additional triggers)
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

IF UPDATE(ROEDate)
BEGIN
	RAISERROR('ROEDate cannot be updated, it is part of a Key Value.', 11, -1)
    ROLLBACK TRANSACTION
END

IF UPDATE(Employee)
BEGIN
	RAISERROR('Employee ID cannot be updated, it is a Key Value.', 11, -1)
    ROLLBACK TRANSACTION
END

IF UPDATE(PayPeriodEndingDate)
BEGIN
	RAISERROR('Pay Period Ending Date cannot be updated, it is a Key Value.', 11, -1)
    ROLLBACK TRANSACTION
END


/* add HQ Master Audit entry */

-- InsurableEarnings
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeInsurEarningsPPD', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10))
		+ ', PayPeriodEndingDate: ' + CAST(i.PayPeriodEndingDate AS VARCHAR(10)),  
		i.PRCo, 
		'C',
		'InsurableEarnings',
		d.InsurableEarnings,
		i.InsurableEarnings,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee AND i.PayPeriodEndingDate = d.PayPeriodEndingDate
        WHERE ISNULL(i.InsurableEarnings,'') <> ISNULL(d.InsurableEarnings,'') 
			 

RETURN
GO
ALTER TABLE [dbo].[vPRROEEmployeeInsurEarningsPPD] ADD CONSTRAINT [PK_vPRROEEmployeeInsurEarningsPPD_KeyID] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPRROEEmployeeInsurEarningsPPD_PRCo_Employee_ROEDate_PayPeriodEndingDate] ON [dbo].[vPRROEEmployeeInsurEarningsPPD] ([PRCo], [Employee], [ROEDate], [PayPeriodEndingDate]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPRROEEmployeeInsurEarningsPPD] WITH NOCHECK ADD CONSTRAINT [FK_vPRROEEmployeeInsurEarningsPPD_vPRROEEmployeeHistory] FOREIGN KEY ([PRCo], [Employee], [ROEDate]) REFERENCES [dbo].[vPRROEEmployeeHistory] ([PRCo], [Employee], [ROEDate]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vPRROEEmployeeInsurEarningsPPD] NOCHECK CONSTRAINT [FK_vPRROEEmployeeInsurEarningsPPD_vPRROEEmployeeHistory]
GO
