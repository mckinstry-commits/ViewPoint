CREATE TABLE [dbo].[bPRUP]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[UserName] [dbo].[bVPUserName] NOT NULL,
[JCCo1] [tinyint] NOT NULL,
[GLCo] [tinyint] NOT NULL,
[InsCode1] [tinyint] NOT NULL,
[EMCo1] [tinyint] NOT NULL,
[Equip] [tinyint] NOT NULL,
[Class1] [tinyint] NOT NULL,
[Shift1] [tinyint] NOT NULL,
[Rate1] [tinyint] NOT NULL,
[Amt1] [tinyint] NOT NULL,
[EMCo2] [tinyint] NOT NULL,
[EMCo3] [tinyint] NOT NULL,
[WO] [tinyint] NOT NULL,
[WOItem] [tinyint] NOT NULL,
[CompType] [tinyint] NOT NULL,
[Comp] [tinyint] NOT NULL,
[InsCode2] [tinyint] NOT NULL,
[Class2] [tinyint] NOT NULL,
[Shift2] [tinyint] NOT NULL,
[Rate2] [tinyint] NOT NULL,
[Amt2] [tinyint] NOT NULL,
[JCCo2] [tinyint] NOT NULL,
[Job] [tinyint] NOT NULL,
[PRDept1] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_PRDept1] DEFAULT ((0)),
[PRDept2] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_PRDept2] DEFAULT ((0)),
[Memo1] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Memo1] DEFAULT ((0)),
[Memo2] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Memo2] DEFAULT ((0)),
[UniqueAttchID] [uniqueidentifier] NULL,
[Craft1] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Craft1] DEFAULT ((0)),
[EquipPhase1] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_EquipPhase1] DEFAULT ((0)),
[CostType1] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_CostType1] DEFAULT ((0)),
[Craft2] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Craft2] DEFAULT ((0)),
[PaySeq1] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_PaySeq1] DEFAULT ((1)),
[Crew1] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Crew1] DEFAULT ((1)),
[InsState1] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_InsState1] DEFAULT ((1)),
[TaxState1] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_TaxState1] DEFAULT ((1)),
[Local1] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Local1] DEFAULT ((1)),
[UnempState1] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_UnempState1] DEFAULT ((1)),
[Cert1] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Cert1] DEFAULT ((1)),
[PaySeq2] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_PaySeq2] DEFAULT ((1)),
[Crew2] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Crew2] DEFAULT ((1)),
[InsState2] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_InsState2] DEFAULT ((1)),
[TaxState2] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_TaxState2] DEFAULT ((1)),
[Local2] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Local2] DEFAULT ((1)),
[UnempState2] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_UnempState2] DEFAULT ((1)),
[Cert2] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Cert2] DEFAULT ((1)),
[Job1] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Job1] DEFAULT ((2)),
[Phase1] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Phase1] DEFAULT ((2)),
[RevCode1] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_RevCode1] DEFAULT ((4)),
[Equip2] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Equip2] DEFAULT ((2)),
[CostCode2] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_CostCode2] DEFAULT ((2)),
[SkipPaySeq1] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipPaySeq1] DEFAULT ('N'),
[SkipPRDept1] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipPRDept1] DEFAULT ('N'),
[SkipCrew1] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipCrew1] DEFAULT ('N'),
[SkipJCCo1] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipJCCo1] DEFAULT ('N'),
[SkipInsState1] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipInsState1] DEFAULT ('N'),
[SkipTaxState1] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipTaxState1] DEFAULT ('N'),
[SkipLocal1] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipLocal1] DEFAULT ('N'),
[SkipUnempState1] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipUnempState1] DEFAULT ('N'),
[SkipInsCode1] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipInsCode1] DEFAULT ('N'),
[SkipGLCo1] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipGLCo1] DEFAULT ('N'),
[SkipEMCo1] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipEMCo1] DEFAULT ('N'),
[SkipEquip1] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipEquip1] DEFAULT ('N'),
[SkipCraft1] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipCraft1] DEFAULT ('N'),
[SkipClass1] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipClass1] DEFAULT ('N'),
[SkipShift1] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipShift1] DEFAULT ('N'),
[SkipRate1] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipRate1] DEFAULT ('N'),
[SkipAmt1] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipAmt1] DEFAULT ('N'),
[SkipEquipPhase1] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipEquipPhase1] DEFAULT ('N'),
[SkipCostType1] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipCostType1] DEFAULT ('N'),
[SkipRevCode1] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipRevCode1] DEFAULT ('N'),
[SkipCert1] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipCert1] DEFAULT ('N'),
[SkipMemo1] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipMemo1] DEFAULT ('N'),
[SkipPaySeq2] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipPaySeq2] DEFAULT ('N'),
[SkipPRDept2] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipPRDept2] DEFAULT ('N'),
[SkipCrew2] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipCrew2] DEFAULT ('N'),
[SkipJCCo2] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipJCCo2] DEFAULT ('N'),
[SkipJob2] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipJob2] DEFAULT ('N'),
[SkipInsState2] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipInsState2] DEFAULT ('N'),
[SkipTaxState2] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipTaxState2] DEFAULT ('N'),
[SkipLocal2] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipLocal2] DEFAULT ('N'),
[SkipUnempState2] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipUnempState2] DEFAULT ('N'),
[SkipInsCode2] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipInsCode2] DEFAULT ('N'),
[SkipWO2] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipWO2] DEFAULT ('N'),
[SkipWOItem2] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipWOItem2] DEFAULT ('N'),
[SkipEMCo2] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipEMCo2] DEFAULT ('N'),
[SkipCompType2] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipCompType2] DEFAULT ('N'),
[SkipComp2] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipComp2] DEFAULT ('N'),
[SkipCraft2] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipCraft2] DEFAULT ('N'),
[SkipClass2] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipClass2] DEFAULT ('N'),
[SkipShift2] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipShift2] DEFAULT ('N'),
[SkipRate2] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipRate2] DEFAULT ('N'),
[SkipAmt2] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipAmt2] DEFAULT ('N'),
[SkipCert2] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipCert2] DEFAULT ('N'),
[SkipMemo2] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipMemo2] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Employee1] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Employee1] DEFAULT ((2)),
[Employee2] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Employee2] DEFAULT ((2)),
[Type1] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Type1] DEFAULT ((2)),
[SkipType1] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipType1] DEFAULT ('N'),
[Type2] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Type2] DEFAULT ((2)),
[SkipType2] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipType2] DEFAULT ('N'),
[Employee3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Employee3] DEFAULT ((0)),
[Type3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Type3] DEFAULT ((2)),
[PaySeq3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_PaySeq3] DEFAULT ((2)),
[PRDept3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_PRDept3] DEFAULT ((3)),
[Crew3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Crew3] DEFAULT ((3)),
[JCCo3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_JCCo3] DEFAULT ((0)),
[Job3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Job3] DEFAULT ((0)),
[Phase3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Phase3] DEFAULT ((0)),
[InsState3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_InsState3] DEFAULT ((2)),
[TaxState3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_TaxState3] DEFAULT ((2)),
[Local3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Local3] DEFAULT ((3)),
[UnempState3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_UnempState3] DEFAULT ((2)),
[InsCode3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_InsCode3] DEFAULT ((3)),
[Craft3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Craft3] DEFAULT ((3)),
[GLCo3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_GLCo3] DEFAULT ((2)),
[Equip3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Equip3] DEFAULT ((3)),
[Class3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Class3] DEFAULT ((3)),
[Shift3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Shift3] DEFAULT ((2)),
[Rate3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Rate3] DEFAULT ((2)),
[Amt3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Amt3] DEFAULT ((2)),
[EquipPhase3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_EquipPhase3] DEFAULT ((3)),
[CostType3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_CostType3] DEFAULT ((0)),
[RevCode3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_RevCode3] DEFAULT ((0)),
[Cert3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Cert3] DEFAULT ((2)),
[SMCo3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_SMCo3] DEFAULT ((2)),
[SMWo3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_SMWo3] DEFAULT ((0)),
[SMScope3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_SMScope3] DEFAULT ((0)),
[SMPayType3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_SMPayType3] DEFAULT ((0)),
[SMCostType3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_SMCostType3] DEFAULT ((0)),
[SMJCCostType3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_SMJCCostType3] DEFAULT ((0)),
[SkipSMCostType3] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipSMCostType3] DEFAULT ('N'),
[SkipSMJCCostType3] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipSMJCCostType3] DEFAULT ('N'),
[Memo3] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_Memo3] DEFAULT ((2)),
[SkipType3] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipType3] DEFAULT ('N'),
[SkipPaySeq3] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipPaySeq3] DEFAULT ('N'),
[SkipPRDept3] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipPRDept3] DEFAULT ('N'),
[SkipInsState3] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipInsState3] DEFAULT ('N'),
[SkipTaxState3] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipTaxState3] DEFAULT ('N'),
[SkipLocal3] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipLocal3] DEFAULT ('N'),
[SkipUnempState3] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipUnempState3] DEFAULT ('N'),
[SkipInsCode3] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipInsCode3] DEFAULT ('N'),
[SkipCraft3] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipCraft3] DEFAULT ('N'),
[SkipGLCo3] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipGLCo3] DEFAULT ('N'),
[SkipEquip3] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipEquip3] DEFAULT ('N'),
[SkipClass3] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipClass3] DEFAULT ('N'),
[SkipShift3] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipShift3] DEFAULT ('N'),
[SkipRate3] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipRate3] DEFAULT ('N'),
[SkipAmt3] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipAmt3] DEFAULT ('N'),
[SkipEquipPhase3] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipEquipPhase3] DEFAULT ('N'),
[SkipCostType3] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipCostType3] DEFAULT ('N'),
[SkipRevCode3] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipRevCode3] DEFAULT ('N'),
[SkipCert3] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipCert3] DEFAULT ('N'),
[SkipSMCo3] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipSMCo3] DEFAULT ('N'),
[SkipMemo3] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipMemo3] DEFAULT ('N'),
[EMCo4] [tinyint] NOT NULL CONSTRAINT [DF_bPRUP_EMCo4] DEFAULT ((2)),
[SkipEMCo4] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipEMCo4] DEFAULT ('N'),
[SkipCrew3] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRUP_SkipCrew3] DEFAULT ('N')
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRUP] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRUP] ON [dbo].[bPRUP] ([PRCo], [UserName]) ON [PRIMARY]
GO
