CREATE TABLE [dbo].[vSMDepartment]
(
[SMDepartmentID] [bigint] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NOT NULL,
[Department] [dbo].[bDept] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[EquipCostGLAcct] [dbo].[bGLAcct] NOT NULL,
[LaborCostGLAcct] [dbo].[bGLAcct] NOT NULL,
[MiscCostGLAcct] [dbo].[bGLAcct] NOT NULL,
[MaterialCostGLAcct] [dbo].[bGLAcct] NOT NULL,
[PurchaseCostGLAcct] [dbo].[bGLAcct] NOT NULL,
[EquipRevGLAcct] [dbo].[bGLAcct] NOT NULL,
[LaborRevGLAcct] [dbo].[bGLAcct] NOT NULL,
[MiscRevGLAcct] [dbo].[bGLAcct] NOT NULL,
[MaterialRevGLAcct] [dbo].[bGLAcct] NOT NULL,
[PurchaseRevGLAcct] [dbo].[bGLAcct] NOT NULL,
[EquipCostWIPGLAcct] [dbo].[bGLAcct] NOT NULL,
[LaborCostWIPGLAcct] [dbo].[bGLAcct] NOT NULL,
[MiscCostWIPGLAcct] [dbo].[bGLAcct] NOT NULL,
[MaterialCostWIPGLAcct] [dbo].[bGLAcct] NOT NULL,
[PurchaseCostWIPGLAcct] [dbo].[bGLAcct] NOT NULL,
[EquipRevWIPGLAcct] [dbo].[bGLAcct] NOT NULL,
[LaborRevWIPGLAcct] [dbo].[bGLAcct] NOT NULL,
[MiscRevWIPGLAcct] [dbo].[bGLAcct] NOT NULL,
[MaterialRevWIPGLAcct] [dbo].[bGLAcct] NOT NULL,
[PurchaseRevWIPGLAcct] [dbo].[bGLAcct] NOT NULL,
[AgreementRevGLAcct] [dbo].[bGLAcct] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[vSMDepartment] WITH NOCHECK ADD
CONSTRAINT [FK_vSMDepartment_bGLAC_AgreementRevGLAcct] FOREIGN KEY ([GLCo], [AgreementRevGLAcct]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
ALTER TABLE [dbo].[vSMDepartment] WITH NOCHECK ADD
CONSTRAINT [FK_vSMDepartment_bGLAC_EquipCostGLAcct] FOREIGN KEY ([GLCo], [EquipCostGLAcct]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
ALTER TABLE [dbo].[vSMDepartment] WITH NOCHECK ADD
CONSTRAINT [FK_vSMDepartment_bGLAC_EquipCostWIPGLAcct] FOREIGN KEY ([GLCo], [EquipCostWIPGLAcct]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
ALTER TABLE [dbo].[vSMDepartment] WITH NOCHECK ADD
CONSTRAINT [FK_vSMDepartment_bGLAC_EquipRevGLAcct] FOREIGN KEY ([GLCo], [EquipRevGLAcct]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
ALTER TABLE [dbo].[vSMDepartment] WITH NOCHECK ADD
CONSTRAINT [FK_vSMDepartment_bGLAC_EquipRevWIPGLAcct] FOREIGN KEY ([GLCo], [EquipRevWIPGLAcct]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
ALTER TABLE [dbo].[vSMDepartment] WITH NOCHECK ADD
CONSTRAINT [FK_vSMDepartment_bGLAC_LaborCostGLAcct] FOREIGN KEY ([GLCo], [LaborCostGLAcct]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
ALTER TABLE [dbo].[vSMDepartment] WITH NOCHECK ADD
CONSTRAINT [FK_vSMDepartment_bGLAC_LaborCostWIPGLAcct] FOREIGN KEY ([GLCo], [LaborCostWIPGLAcct]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
ALTER TABLE [dbo].[vSMDepartment] WITH NOCHECK ADD
CONSTRAINT [FK_vSMDepartment_bGLAC_LaborRevGLAcct] FOREIGN KEY ([GLCo], [LaborRevGLAcct]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
ALTER TABLE [dbo].[vSMDepartment] WITH NOCHECK ADD
CONSTRAINT [FK_vSMDepartment_bGLAC_LaborRevWIPGLAcct] FOREIGN KEY ([GLCo], [LaborRevWIPGLAcct]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
ALTER TABLE [dbo].[vSMDepartment] WITH NOCHECK ADD
CONSTRAINT [FK_vSMDepartment_bGLAC_MaterialCostGLAcct] FOREIGN KEY ([GLCo], [MaterialCostGLAcct]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
ALTER TABLE [dbo].[vSMDepartment] WITH NOCHECK ADD
CONSTRAINT [FK_vSMDepartment_bGLAC_MaterialCostWIPGLAcct] FOREIGN KEY ([GLCo], [MaterialCostWIPGLAcct]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
ALTER TABLE [dbo].[vSMDepartment] WITH NOCHECK ADD
CONSTRAINT [FK_vSMDepartment_bGLAC_MaterialRevGLAcct] FOREIGN KEY ([GLCo], [MaterialRevGLAcct]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
ALTER TABLE [dbo].[vSMDepartment] WITH NOCHECK ADD
CONSTRAINT [FK_vSMDepartment_bGLAC_MaterialRevWIPGLAcct] FOREIGN KEY ([GLCo], [MaterialRevWIPGLAcct]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
ALTER TABLE [dbo].[vSMDepartment] WITH NOCHECK ADD
CONSTRAINT [FK_vSMDepartment_bGLAC_MiscCostGLAcct] FOREIGN KEY ([GLCo], [MiscCostGLAcct]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
ALTER TABLE [dbo].[vSMDepartment] WITH NOCHECK ADD
CONSTRAINT [FK_vSMDepartment_bGLAC_MiscCostWIPGLAcct] FOREIGN KEY ([GLCo], [MiscCostWIPGLAcct]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
ALTER TABLE [dbo].[vSMDepartment] WITH NOCHECK ADD
CONSTRAINT [FK_vSMDepartment_bGLAC_MiscRevGLAcct] FOREIGN KEY ([GLCo], [MiscRevGLAcct]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
ALTER TABLE [dbo].[vSMDepartment] WITH NOCHECK ADD
CONSTRAINT [FK_vSMDepartment_bGLAC_MiscRevWIPGLAcct] FOREIGN KEY ([GLCo], [MiscRevWIPGLAcct]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
ALTER TABLE [dbo].[vSMDepartment] WITH NOCHECK ADD
CONSTRAINT [FK_vSMDepartment_bGLAC_PurchaseCostGLAcct] FOREIGN KEY ([GLCo], [PurchaseCostGLAcct]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
ALTER TABLE [dbo].[vSMDepartment] WITH NOCHECK ADD
CONSTRAINT [FK_vSMDepartment_bGLAC_PurchaseCostWIPGLAcct] FOREIGN KEY ([GLCo], [PurchaseCostWIPGLAcct]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
ALTER TABLE [dbo].[vSMDepartment] WITH NOCHECK ADD
CONSTRAINT [FK_vSMDepartment_bGLAC_PurchaseRevGLAcct] FOREIGN KEY ([GLCo], [PurchaseRevGLAcct]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
ALTER TABLE [dbo].[vSMDepartment] WITH NOCHECK ADD
CONSTRAINT [FK_vSMDepartment_bGLAC_PurchaseRevWIPGLAcct] FOREIGN KEY ([GLCo], [PurchaseRevWIPGLAcct]) REFERENCES [dbo].[bGLAC] ([GLCo], [GLAcct])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMDepartment_Audit_Delete ON dbo.vSMDepartment
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspAuditCreateAuditTriggers

 BEGIN TRY 

							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMDepartment' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'AgreementRevGLAcct' , 
								CONVERT(VARCHAR(MAX), deleted.[AgreementRevGLAcct]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMDepartment' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'Department' , 
								CONVERT(VARCHAR(MAX), deleted.[Department]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMDepartment' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'Description' , 
								CONVERT(VARCHAR(MAX), deleted.[Description]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMDepartment' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'EquipCostGLAcct' , 
								CONVERT(VARCHAR(MAX), deleted.[EquipCostGLAcct]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMDepartment' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'EquipCostWIPGLAcct' , 
								CONVERT(VARCHAR(MAX), deleted.[EquipCostWIPGLAcct]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMDepartment' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'EquipRevGLAcct' , 
								CONVERT(VARCHAR(MAX), deleted.[EquipRevGLAcct]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMDepartment' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'EquipRevWIPGLAcct' , 
								CONVERT(VARCHAR(MAX), deleted.[EquipRevWIPGLAcct]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMDepartment' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'GLCo' , 
								CONVERT(VARCHAR(MAX), deleted.[GLCo]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMDepartment' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'LaborCostGLAcct' , 
								CONVERT(VARCHAR(MAX), deleted.[LaborCostGLAcct]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMDepartment' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'LaborCostWIPGLAcct' , 
								CONVERT(VARCHAR(MAX), deleted.[LaborCostWIPGLAcct]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMDepartment' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'LaborRevGLAcct' , 
								CONVERT(VARCHAR(MAX), deleted.[LaborRevGLAcct]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMDepartment' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'LaborRevWIPGLAcct' , 
								CONVERT(VARCHAR(MAX), deleted.[LaborRevWIPGLAcct]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMDepartment' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MaterialCostGLAcct' , 
								CONVERT(VARCHAR(MAX), deleted.[MaterialCostGLAcct]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMDepartment' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MaterialCostWIPGLAcct' , 
								CONVERT(VARCHAR(MAX), deleted.[MaterialCostWIPGLAcct]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMDepartment' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MaterialRevGLAcct' , 
								CONVERT(VARCHAR(MAX), deleted.[MaterialRevGLAcct]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMDepartment' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MaterialRevWIPGLAcct' , 
								CONVERT(VARCHAR(MAX), deleted.[MaterialRevWIPGLAcct]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMDepartment' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MiscCostGLAcct' , 
								CONVERT(VARCHAR(MAX), deleted.[MiscCostGLAcct]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMDepartment' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MiscCostWIPGLAcct' , 
								CONVERT(VARCHAR(MAX), deleted.[MiscCostWIPGLAcct]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMDepartment' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MiscRevGLAcct' , 
								CONVERT(VARCHAR(MAX), deleted.[MiscRevGLAcct]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMDepartment' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'MiscRevWIPGLAcct' , 
								CONVERT(VARCHAR(MAX), deleted.[MiscRevWIPGLAcct]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMDepartment' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'PurchaseCostGLAcct' , 
								CONVERT(VARCHAR(MAX), deleted.[PurchaseCostGLAcct]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMDepartment' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'PurchaseCostWIPGLAcct' , 
								CONVERT(VARCHAR(MAX), deleted.[PurchaseCostWIPGLAcct]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMDepartment' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'PurchaseRevGLAcct' , 
								CONVERT(VARCHAR(MAX), deleted.[PurchaseRevGLAcct]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMDepartment' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'PurchaseRevWIPGLAcct' , 
								CONVERT(VARCHAR(MAX), deleted.[PurchaseRevWIPGLAcct]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMDepartment' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'SMCo' , 
								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMDepartment' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'SMDepartmentID' , 
								CONVERT(VARCHAR(MAX), deleted.[SMDepartmentID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMDepartment' , 
								'<KeyString />' , 
								deleted.SMCo , 
								'D' , 
								'UniqueAttchID' , 
								CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							
 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMDepartment_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMDepartment_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMDepartment_Audit_Insert ON dbo.vSMDepartment
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspAuditTriggersCreate

 BEGIN TRY 

-- log additions to the AgreementRevGLAcct column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMDepartment' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'AgreementRevGLAcct' , 
								NULL , 
								AgreementRevGLAcct , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

-- log additions to the Department column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMDepartment' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Department' , 
								NULL , 
								Department , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

-- log additions to the Description column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMDepartment' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Description' , 
								NULL , 
								Description , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

-- log additions to the EquipCostGLAcct column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMDepartment' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'EquipCostGLAcct' , 
								NULL , 
								EquipCostGLAcct , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

-- log additions to the EquipCostWIPGLAcct column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMDepartment' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'EquipCostWIPGLAcct' , 
								NULL , 
								EquipCostWIPGLAcct , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

-- log additions to the EquipRevGLAcct column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMDepartment' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'EquipRevGLAcct' , 
								NULL , 
								EquipRevGLAcct , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

-- log additions to the EquipRevWIPGLAcct column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMDepartment' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'EquipRevWIPGLAcct' , 
								NULL , 
								EquipRevWIPGLAcct , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

-- log additions to the GLCo column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMDepartment' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'GLCo' , 
								NULL , 
								GLCo , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

-- log additions to the LaborCostGLAcct column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMDepartment' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'LaborCostGLAcct' , 
								NULL , 
								LaborCostGLAcct , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

-- log additions to the LaborCostWIPGLAcct column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMDepartment' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'LaborCostWIPGLAcct' , 
								NULL , 
								LaborCostWIPGLAcct , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

-- log additions to the LaborRevGLAcct column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMDepartment' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'LaborRevGLAcct' , 
								NULL , 
								LaborRevGLAcct , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

-- log additions to the LaborRevWIPGLAcct column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMDepartment' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'LaborRevWIPGLAcct' , 
								NULL , 
								LaborRevWIPGLAcct , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

-- log additions to the MaterialCostGLAcct column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMDepartment' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MaterialCostGLAcct' , 
								NULL , 
								MaterialCostGLAcct , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

-- log additions to the MaterialCostWIPGLAcct column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMDepartment' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MaterialCostWIPGLAcct' , 
								NULL , 
								MaterialCostWIPGLAcct , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

-- log additions to the MaterialRevGLAcct column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMDepartment' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MaterialRevGLAcct' , 
								NULL , 
								MaterialRevGLAcct , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

-- log additions to the MaterialRevWIPGLAcct column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMDepartment' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MaterialRevWIPGLAcct' , 
								NULL , 
								MaterialRevWIPGLAcct , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

-- log additions to the MiscCostGLAcct column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMDepartment' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MiscCostGLAcct' , 
								NULL , 
								MiscCostGLAcct , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

-- log additions to the MiscCostWIPGLAcct column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMDepartment' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MiscCostWIPGLAcct' , 
								NULL , 
								MiscCostWIPGLAcct , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

-- log additions to the MiscRevGLAcct column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMDepartment' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MiscRevGLAcct' , 
								NULL , 
								MiscRevGLAcct , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

-- log additions to the MiscRevWIPGLAcct column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMDepartment' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'MiscRevWIPGLAcct' , 
								NULL , 
								MiscRevWIPGLAcct , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

-- log additions to the PurchaseCostGLAcct column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMDepartment' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PurchaseCostGLAcct' , 
								NULL , 
								PurchaseCostGLAcct , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

-- log additions to the PurchaseCostWIPGLAcct column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMDepartment' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PurchaseCostWIPGLAcct' , 
								NULL , 
								PurchaseCostWIPGLAcct , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

-- log additions to the PurchaseRevGLAcct column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMDepartment' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PurchaseRevGLAcct' , 
								NULL , 
								PurchaseRevGLAcct , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

-- log additions to the PurchaseRevWIPGLAcct column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMDepartment' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PurchaseRevWIPGLAcct' , 
								NULL , 
								PurchaseRevWIPGLAcct , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

-- log additions to the SMCo column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMDepartment' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMCo' , 
								NULL , 
								SMCo , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

-- log additions to the SMDepartmentID column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMDepartment' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMDepartmentID' , 
								NULL , 
								SMDepartmentID , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

-- log additions to the UniqueAttchID column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMDepartment' , 
								'<KeyString />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'UniqueAttchID' , 
								NULL , 
								UniqueAttchID , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8


 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMDepartment_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMDepartment_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMDepartment_Audit_Update ON dbo.vSMDepartment
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspAuditTriggersCreate

 BEGIN TRY 

							IF UPDATE([AgreementRevGLAcct])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMDepartment' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'AgreementRevGLAcct' , 								CONVERT(VARCHAR(MAX), deleted.[AgreementRevGLAcct]) , 								CONVERT(VARCHAR(MAX), inserted.[AgreementRevGLAcct]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMDepartmentID] = deleted.[SMDepartmentID] 
									AND ((inserted.[AgreementRevGLAcct] <> deleted.[AgreementRevGLAcct]) OR (inserted.[AgreementRevGLAcct] IS NULL AND deleted.[AgreementRevGLAcct] IS NOT NULL) OR (inserted.[AgreementRevGLAcct] IS NOT NULL AND deleted.[AgreementRevGLAcct] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							END 

							IF UPDATE([Department])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMDepartment' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'Department' , 								CONVERT(VARCHAR(MAX), deleted.[Department]) , 								CONVERT(VARCHAR(MAX), inserted.[Department]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMDepartmentID] = deleted.[SMDepartmentID] 
									AND ((inserted.[Department] <> deleted.[Department]) OR (inserted.[Department] IS NULL AND deleted.[Department] IS NOT NULL) OR (inserted.[Department] IS NOT NULL AND deleted.[Department] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							END 

							IF UPDATE([Description])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMDepartment' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'Description' , 								CONVERT(VARCHAR(MAX), deleted.[Description]) , 								CONVERT(VARCHAR(MAX), inserted.[Description]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMDepartmentID] = deleted.[SMDepartmentID] 
									AND ((inserted.[Description] <> deleted.[Description]) OR (inserted.[Description] IS NULL AND deleted.[Description] IS NOT NULL) OR (inserted.[Description] IS NOT NULL AND deleted.[Description] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							END 

							IF UPDATE([EquipCostGLAcct])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMDepartment' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'EquipCostGLAcct' , 								CONVERT(VARCHAR(MAX), deleted.[EquipCostGLAcct]) , 								CONVERT(VARCHAR(MAX), inserted.[EquipCostGLAcct]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMDepartmentID] = deleted.[SMDepartmentID] 
									AND ((inserted.[EquipCostGLAcct] <> deleted.[EquipCostGLAcct]) OR (inserted.[EquipCostGLAcct] IS NULL AND deleted.[EquipCostGLAcct] IS NOT NULL) OR (inserted.[EquipCostGLAcct] IS NOT NULL AND deleted.[EquipCostGLAcct] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							END 

							IF UPDATE([EquipCostWIPGLAcct])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMDepartment' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'EquipCostWIPGLAcct' , 								CONVERT(VARCHAR(MAX), deleted.[EquipCostWIPGLAcct]) , 								CONVERT(VARCHAR(MAX), inserted.[EquipCostWIPGLAcct]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMDepartmentID] = deleted.[SMDepartmentID] 
									AND ((inserted.[EquipCostWIPGLAcct] <> deleted.[EquipCostWIPGLAcct]) OR (inserted.[EquipCostWIPGLAcct] IS NULL AND deleted.[EquipCostWIPGLAcct] IS NOT NULL) OR (inserted.[EquipCostWIPGLAcct] IS NOT NULL AND deleted.[EquipCostWIPGLAcct] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							END 

							IF UPDATE([EquipRevGLAcct])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMDepartment' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'EquipRevGLAcct' , 								CONVERT(VARCHAR(MAX), deleted.[EquipRevGLAcct]) , 								CONVERT(VARCHAR(MAX), inserted.[EquipRevGLAcct]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMDepartmentID] = deleted.[SMDepartmentID] 
									AND ((inserted.[EquipRevGLAcct] <> deleted.[EquipRevGLAcct]) OR (inserted.[EquipRevGLAcct] IS NULL AND deleted.[EquipRevGLAcct] IS NOT NULL) OR (inserted.[EquipRevGLAcct] IS NOT NULL AND deleted.[EquipRevGLAcct] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							END 

							IF UPDATE([EquipRevWIPGLAcct])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMDepartment' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'EquipRevWIPGLAcct' , 								CONVERT(VARCHAR(MAX), deleted.[EquipRevWIPGLAcct]) , 								CONVERT(VARCHAR(MAX), inserted.[EquipRevWIPGLAcct]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMDepartmentID] = deleted.[SMDepartmentID] 
									AND ((inserted.[EquipRevWIPGLAcct] <> deleted.[EquipRevWIPGLAcct]) OR (inserted.[EquipRevWIPGLAcct] IS NULL AND deleted.[EquipRevWIPGLAcct] IS NOT NULL) OR (inserted.[EquipRevWIPGLAcct] IS NOT NULL AND deleted.[EquipRevWIPGLAcct] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							END 

							IF UPDATE([GLCo])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMDepartment' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'GLCo' , 								CONVERT(VARCHAR(MAX), deleted.[GLCo]) , 								CONVERT(VARCHAR(MAX), inserted.[GLCo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMDepartmentID] = deleted.[SMDepartmentID] 
									AND ((inserted.[GLCo] <> deleted.[GLCo]) OR (inserted.[GLCo] IS NULL AND deleted.[GLCo] IS NOT NULL) OR (inserted.[GLCo] IS NOT NULL AND deleted.[GLCo] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							END 

							IF UPDATE([LaborCostGLAcct])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMDepartment' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'LaborCostGLAcct' , 								CONVERT(VARCHAR(MAX), deleted.[LaborCostGLAcct]) , 								CONVERT(VARCHAR(MAX), inserted.[LaborCostGLAcct]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMDepartmentID] = deleted.[SMDepartmentID] 
									AND ((inserted.[LaborCostGLAcct] <> deleted.[LaborCostGLAcct]) OR (inserted.[LaborCostGLAcct] IS NULL AND deleted.[LaborCostGLAcct] IS NOT NULL) OR (inserted.[LaborCostGLAcct] IS NOT NULL AND deleted.[LaborCostGLAcct] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							END 

							IF UPDATE([LaborCostWIPGLAcct])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMDepartment' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'LaborCostWIPGLAcct' , 								CONVERT(VARCHAR(MAX), deleted.[LaborCostWIPGLAcct]) , 								CONVERT(VARCHAR(MAX), inserted.[LaborCostWIPGLAcct]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMDepartmentID] = deleted.[SMDepartmentID] 
									AND ((inserted.[LaborCostWIPGLAcct] <> deleted.[LaborCostWIPGLAcct]) OR (inserted.[LaborCostWIPGLAcct] IS NULL AND deleted.[LaborCostWIPGLAcct] IS NOT NULL) OR (inserted.[LaborCostWIPGLAcct] IS NOT NULL AND deleted.[LaborCostWIPGLAcct] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							END 

							IF UPDATE([LaborRevGLAcct])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMDepartment' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'LaborRevGLAcct' , 								CONVERT(VARCHAR(MAX), deleted.[LaborRevGLAcct]) , 								CONVERT(VARCHAR(MAX), inserted.[LaborRevGLAcct]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMDepartmentID] = deleted.[SMDepartmentID] 
									AND ((inserted.[LaborRevGLAcct] <> deleted.[LaborRevGLAcct]) OR (inserted.[LaborRevGLAcct] IS NULL AND deleted.[LaborRevGLAcct] IS NOT NULL) OR (inserted.[LaborRevGLAcct] IS NOT NULL AND deleted.[LaborRevGLAcct] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							END 

							IF UPDATE([LaborRevWIPGLAcct])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMDepartment' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'LaborRevWIPGLAcct' , 								CONVERT(VARCHAR(MAX), deleted.[LaborRevWIPGLAcct]) , 								CONVERT(VARCHAR(MAX), inserted.[LaborRevWIPGLAcct]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMDepartmentID] = deleted.[SMDepartmentID] 
									AND ((inserted.[LaborRevWIPGLAcct] <> deleted.[LaborRevWIPGLAcct]) OR (inserted.[LaborRevWIPGLAcct] IS NULL AND deleted.[LaborRevWIPGLAcct] IS NOT NULL) OR (inserted.[LaborRevWIPGLAcct] IS NOT NULL AND deleted.[LaborRevWIPGLAcct] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							END 

							IF UPDATE([MaterialCostGLAcct])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMDepartment' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MaterialCostGLAcct' , 								CONVERT(VARCHAR(MAX), deleted.[MaterialCostGLAcct]) , 								CONVERT(VARCHAR(MAX), inserted.[MaterialCostGLAcct]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMDepartmentID] = deleted.[SMDepartmentID] 
									AND ((inserted.[MaterialCostGLAcct] <> deleted.[MaterialCostGLAcct]) OR (inserted.[MaterialCostGLAcct] IS NULL AND deleted.[MaterialCostGLAcct] IS NOT NULL) OR (inserted.[MaterialCostGLAcct] IS NOT NULL AND deleted.[MaterialCostGLAcct] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							END 

							IF UPDATE([MaterialCostWIPGLAcct])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMDepartment' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MaterialCostWIPGLAcct' , 								CONVERT(VARCHAR(MAX), deleted.[MaterialCostWIPGLAcct]) , 								CONVERT(VARCHAR(MAX), inserted.[MaterialCostWIPGLAcct]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMDepartmentID] = deleted.[SMDepartmentID] 
									AND ((inserted.[MaterialCostWIPGLAcct] <> deleted.[MaterialCostWIPGLAcct]) OR (inserted.[MaterialCostWIPGLAcct] IS NULL AND deleted.[MaterialCostWIPGLAcct] IS NOT NULL) OR (inserted.[MaterialCostWIPGLAcct] IS NOT NULL AND deleted.[MaterialCostWIPGLAcct] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							END 

							IF UPDATE([MaterialRevGLAcct])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMDepartment' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MaterialRevGLAcct' , 								CONVERT(VARCHAR(MAX), deleted.[MaterialRevGLAcct]) , 								CONVERT(VARCHAR(MAX), inserted.[MaterialRevGLAcct]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMDepartmentID] = deleted.[SMDepartmentID] 
									AND ((inserted.[MaterialRevGLAcct] <> deleted.[MaterialRevGLAcct]) OR (inserted.[MaterialRevGLAcct] IS NULL AND deleted.[MaterialRevGLAcct] IS NOT NULL) OR (inserted.[MaterialRevGLAcct] IS NOT NULL AND deleted.[MaterialRevGLAcct] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							END 

							IF UPDATE([MaterialRevWIPGLAcct])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMDepartment' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MaterialRevWIPGLAcct' , 								CONVERT(VARCHAR(MAX), deleted.[MaterialRevWIPGLAcct]) , 								CONVERT(VARCHAR(MAX), inserted.[MaterialRevWIPGLAcct]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMDepartmentID] = deleted.[SMDepartmentID] 
									AND ((inserted.[MaterialRevWIPGLAcct] <> deleted.[MaterialRevWIPGLAcct]) OR (inserted.[MaterialRevWIPGLAcct] IS NULL AND deleted.[MaterialRevWIPGLAcct] IS NOT NULL) OR (inserted.[MaterialRevWIPGLAcct] IS NOT NULL AND deleted.[MaterialRevWIPGLAcct] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							END 

							IF UPDATE([MiscCostGLAcct])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMDepartment' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MiscCostGLAcct' , 								CONVERT(VARCHAR(MAX), deleted.[MiscCostGLAcct]) , 								CONVERT(VARCHAR(MAX), inserted.[MiscCostGLAcct]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMDepartmentID] = deleted.[SMDepartmentID] 
									AND ((inserted.[MiscCostGLAcct] <> deleted.[MiscCostGLAcct]) OR (inserted.[MiscCostGLAcct] IS NULL AND deleted.[MiscCostGLAcct] IS NOT NULL) OR (inserted.[MiscCostGLAcct] IS NOT NULL AND deleted.[MiscCostGLAcct] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							END 

							IF UPDATE([MiscCostWIPGLAcct])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMDepartment' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MiscCostWIPGLAcct' , 								CONVERT(VARCHAR(MAX), deleted.[MiscCostWIPGLAcct]) , 								CONVERT(VARCHAR(MAX), inserted.[MiscCostWIPGLAcct]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMDepartmentID] = deleted.[SMDepartmentID] 
									AND ((inserted.[MiscCostWIPGLAcct] <> deleted.[MiscCostWIPGLAcct]) OR (inserted.[MiscCostWIPGLAcct] IS NULL AND deleted.[MiscCostWIPGLAcct] IS NOT NULL) OR (inserted.[MiscCostWIPGLAcct] IS NOT NULL AND deleted.[MiscCostWIPGLAcct] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							END 

							IF UPDATE([MiscRevGLAcct])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMDepartment' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MiscRevGLAcct' , 								CONVERT(VARCHAR(MAX), deleted.[MiscRevGLAcct]) , 								CONVERT(VARCHAR(MAX), inserted.[MiscRevGLAcct]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMDepartmentID] = deleted.[SMDepartmentID] 
									AND ((inserted.[MiscRevGLAcct] <> deleted.[MiscRevGLAcct]) OR (inserted.[MiscRevGLAcct] IS NULL AND deleted.[MiscRevGLAcct] IS NOT NULL) OR (inserted.[MiscRevGLAcct] IS NOT NULL AND deleted.[MiscRevGLAcct] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							END 

							IF UPDATE([MiscRevWIPGLAcct])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMDepartment' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'MiscRevWIPGLAcct' , 								CONVERT(VARCHAR(MAX), deleted.[MiscRevWIPGLAcct]) , 								CONVERT(VARCHAR(MAX), inserted.[MiscRevWIPGLAcct]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMDepartmentID] = deleted.[SMDepartmentID] 
									AND ((inserted.[MiscRevWIPGLAcct] <> deleted.[MiscRevWIPGLAcct]) OR (inserted.[MiscRevWIPGLAcct] IS NULL AND deleted.[MiscRevWIPGLAcct] IS NOT NULL) OR (inserted.[MiscRevWIPGLAcct] IS NOT NULL AND deleted.[MiscRevWIPGLAcct] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							END 

							IF UPDATE([PurchaseCostGLAcct])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMDepartment' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'PurchaseCostGLAcct' , 								CONVERT(VARCHAR(MAX), deleted.[PurchaseCostGLAcct]) , 								CONVERT(VARCHAR(MAX), inserted.[PurchaseCostGLAcct]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMDepartmentID] = deleted.[SMDepartmentID] 
									AND ((inserted.[PurchaseCostGLAcct] <> deleted.[PurchaseCostGLAcct]) OR (inserted.[PurchaseCostGLAcct] IS NULL AND deleted.[PurchaseCostGLAcct] IS NOT NULL) OR (inserted.[PurchaseCostGLAcct] IS NOT NULL AND deleted.[PurchaseCostGLAcct] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							END 

							IF UPDATE([PurchaseCostWIPGLAcct])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMDepartment' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'PurchaseCostWIPGLAcct' , 								CONVERT(VARCHAR(MAX), deleted.[PurchaseCostWIPGLAcct]) , 								CONVERT(VARCHAR(MAX), inserted.[PurchaseCostWIPGLAcct]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMDepartmentID] = deleted.[SMDepartmentID] 
									AND ((inserted.[PurchaseCostWIPGLAcct] <> deleted.[PurchaseCostWIPGLAcct]) OR (inserted.[PurchaseCostWIPGLAcct] IS NULL AND deleted.[PurchaseCostWIPGLAcct] IS NOT NULL) OR (inserted.[PurchaseCostWIPGLAcct] IS NOT NULL AND deleted.[PurchaseCostWIPGLAcct] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							END 

							IF UPDATE([PurchaseRevGLAcct])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMDepartment' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'PurchaseRevGLAcct' , 								CONVERT(VARCHAR(MAX), deleted.[PurchaseRevGLAcct]) , 								CONVERT(VARCHAR(MAX), inserted.[PurchaseRevGLAcct]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMDepartmentID] = deleted.[SMDepartmentID] 
									AND ((inserted.[PurchaseRevGLAcct] <> deleted.[PurchaseRevGLAcct]) OR (inserted.[PurchaseRevGLAcct] IS NULL AND deleted.[PurchaseRevGLAcct] IS NOT NULL) OR (inserted.[PurchaseRevGLAcct] IS NOT NULL AND deleted.[PurchaseRevGLAcct] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							END 

							IF UPDATE([PurchaseRevWIPGLAcct])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMDepartment' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'PurchaseRevWIPGLAcct' , 								CONVERT(VARCHAR(MAX), deleted.[PurchaseRevWIPGLAcct]) , 								CONVERT(VARCHAR(MAX), inserted.[PurchaseRevWIPGLAcct]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMDepartmentID] = deleted.[SMDepartmentID] 
									AND ((inserted.[PurchaseRevWIPGLAcct] <> deleted.[PurchaseRevWIPGLAcct]) OR (inserted.[PurchaseRevWIPGLAcct] IS NULL AND deleted.[PurchaseRevWIPGLAcct] IS NOT NULL) OR (inserted.[PurchaseRevWIPGLAcct] IS NOT NULL AND deleted.[PurchaseRevWIPGLAcct] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							END 

							IF UPDATE([SMCo])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMDepartment' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'SMCo' , 								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								CONVERT(VARCHAR(MAX), inserted.[SMCo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMDepartmentID] = deleted.[SMDepartmentID] 
									AND ((inserted.[SMCo] <> deleted.[SMCo]) OR (inserted.[SMCo] IS NULL AND deleted.[SMCo] IS NOT NULL) OR (inserted.[SMCo] IS NOT NULL AND deleted.[SMCo] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							END 

							IF UPDATE([SMDepartmentID])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMDepartment' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'SMDepartmentID' , 								CONVERT(VARCHAR(MAX), deleted.[SMDepartmentID]) , 								CONVERT(VARCHAR(MAX), inserted.[SMDepartmentID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMDepartmentID] = deleted.[SMDepartmentID] 
									AND ((inserted.[SMDepartmentID] <> deleted.[SMDepartmentID]) OR (inserted.[SMDepartmentID] IS NULL AND deleted.[SMDepartmentID] IS NOT NULL) OR (inserted.[SMDepartmentID] IS NOT NULL AND deleted.[SMDepartmentID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							END 

							IF UPDATE([UniqueAttchID])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMDepartment' , 								'<KeyString />' , 								inserted.SMCo , 								'C' , 								'UniqueAttchID' , 								CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) , 								CONVERT(VARCHAR(MAX), inserted.[UniqueAttchID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMDepartmentID] = deleted.[SMDepartmentID] 
									AND ((inserted.[UniqueAttchID] <> deleted.[UniqueAttchID]) OR (inserted.[UniqueAttchID] IS NULL AND deleted.[UniqueAttchID] IS NOT NULL) OR (inserted.[UniqueAttchID] IS NOT NULL AND deleted.[UniqueAttchID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 8

							END 



 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMDepartment_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMDepartment_Audit_Update]', 'last', 'update', null
GO
ALTER TABLE [dbo].[vSMDepartment] ADD CONSTRAINT [PK_vSMDepartment] PRIMARY KEY CLUSTERED  ([SMDepartmentID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMDepartment] ADD CONSTRAINT [IX_vSMDepartment_SMCo_Department] UNIQUE NONCLUSTERED  ([SMCo], [Department]) ON [PRIMARY]
GO
