SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE View [dbo].[vrvJCContractMaster]

/*******
 Created:	DH 8/11/2010
 Modified:	HH 8/24/2010 - added TaxInterface column 
			HH 4/21/2011 - changed MonthClosed from '12/1/2050' to '12/2/2050' 
			for empty ThroughMonth parameters on report (logic related to #142697)
 Usage:  View selects columns from JCCM and converts null MonthClosed to 12/1/2050 for open contracts 
		(ContractStatus = 1) so that the comparison MonthClosed > Report Parameter Through Month will return open contracts.  
         Used in all JC reports with a contract that use the (O)pen,(S)oft Closed/Open,(C)losed or (A)ll
         Parameter.
*******/         

as         

select	  JCCo
		, Contract
		, Description
		, Department
		, ContractStatus
		, OriginalDays
		, CurrentDays
		, StartMonth
		, case when ContractStatus<>1 then MonthClosed else '12/2/2050' end as MonthClosedForReport
		, ProjCloseDate
		, ActualCloseDate
		, CustGroup
		, Customer
		, PayTerms
		, TaxGroup
		, TaxCode
		, TaxInterface
		, RetainagePCT
		, DefaultBillType
		, OrigContractAmt
		, ContractAmt
		, BilledAmt
		, ReceivedAmt
		, CurrentRetainAmt
		, Notes
		, SIRegion
		, SIMetric
		, ProcessGroup
		, BillAddress
		, BillAddress2
		, BillCity
		, BillState
		, BillZip
		, BillNotes
		, CustomerReference
		, CompleteYN
		, BillGroup
		, BillDayOfMth
		, ArchitectName
		, ArchitectProject
		, ContractForDesc
		, StartDate
		, OverProjNotes
		, MiscDistCode
		, KeyID
		, BillCountry
		, PotentialProject
		, MaxRetgOpt
		, MaxRetgPct
		, MaxRetgAmt
		, MaxRetgDistStyle
From JCCM		





GO
GRANT SELECT ON  [dbo].[vrvJCContractMaster] TO [public]
GRANT INSERT ON  [dbo].[vrvJCContractMaster] TO [public]
GRANT DELETE ON  [dbo].[vrvJCContractMaster] TO [public]
GRANT UPDATE ON  [dbo].[vrvJCContractMaster] TO [public]
GO
