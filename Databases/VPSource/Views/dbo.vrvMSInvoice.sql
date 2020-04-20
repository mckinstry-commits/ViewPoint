SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE View [dbo].[vrvMSInvoice]
    
	AS

-- first selection collects Invoices and supporting details that have previously printed, valuable for reprints
		 SELECT		[MatlDescription]			=  CASE ISNULL(CONVERT(VARCHAR(500),[MSTD].[SurchargeKeyID]),'Parent') 
													WHEN 'Parent' 
													THEN [HQMT].[Description]	
													ELSE [HQMTSurcharge].[Description] + ' - ' + [HQMT].[Description]
												   END,
					[ParentMaterial]			=  CASE ISNULL(CONVERT(VARCHAR(500),[MSTD].[SurchargeKeyID]),'Parent') 
													WHEN 'Parent' 
													THEN NULL	
													ELSE [MSTDSurcharge].[Material]
												   END,
					[MSTD].[MatlUnits]			AS [MatlUnits],
					[MSTD].[UnitPrice]			AS [MatlUnitPrice],
					[MSTD].[UnitPrice]			AS [MSIDUnitPrice], 
					[MSTD].[ECM]				AS [MatlECM],
					[MSTD].[UM]					AS [MatlUM],
					[MSTD].[UM]					AS [MSIDUM], 
					[MSTD].[MatlTotal]			AS [MatlTotal], 
					[MSTD].[TaxCode]			AS [TaxCode], 
					[MSTD].[TaxTotal]			AS [TaxTotal],
					[MSTD].[HaulTotal]			AS [MatlHaulTotal],
					[MSTD].[SaleDate]			AS [MatlSaleDate],
					[MSTD].[SaleDate]			AS [MSIDSaleDate], 
					[MSTD].[FromLoc]			AS [MatlFromLoc], 
					[MSTD].[FromLoc]			AS [MSIDFromLoc],
					[MSIL].[Material]			AS [Material], 
					[MSTD].[Ticket]				AS [Ticket],
					[MSIH].[SepHaul]			AS [SepHaul], 
					[MSIH].[PrintLvl]			AS [InvPrintLvl], 
					[ARCM].[Name]				AS [CustomerName], 
					[MSIH].[MSInv]				AS [MSInv], 
					[MSIH].[InvDate]			AS [InvDate], 
					[ARCM].[BillAddress]		AS [BillAddress], 
					[ARCM].[BillCity]			AS [BillCity], 
					[ARCM].[BillState]			AS [BillState], 
					[ARCM].[BillZip]			AS [BillZip], 
					[ARCM].[BillAddress2]		AS [BillAddress2], 
					[MSIH].[ShipAddress2]		AS [ShipAddress2], 
					[MSIH].[City]				AS [ShipCity],
					[MSIH].[State]				AS [ShipState], 
					[MSIH].[Zip]				AS [ShipZip], 
					[MSIH].[ShipAddress]		AS [ShipAddress], 
					[MSIH].[Customer]			AS [ShipCustomer], 
					[MSIH].[Void]				AS [Void], 
					[ARCM].[SortName]			AS [CustomerSortName], 
					[MSIH].[MSCo]				AS [Co], 
					[MSIH].[SubtotalLvl]		AS [InvSubtotalLvl], 
					[MSTD].[CustPO]				AS [CustPO],
					[MSTD].[CustPO]				AS [MSIBCustPO],
					[MSTD].[CustPO]				AS [MSIDCustPO],
					[MSTD].[CustJob]			AS [CustJob], 
					[MSTD].[CustJob]			AS [MSIBCustJob],
					[MSTD].[CustJob]			AS [MSIDCustJob],
					[HQPT].[Description]		AS [HQPTDescription], 
					[MSTD].[DiscOff]			AS [DiscOff], 
					[MSIH].[DiscDate]			AS [DiscDate], 
					[MSIH].[PaymentType]		AS [PaymentType], 
					[MSTD].[CheckNo]			AS [CheckNo], 
					[HQCO].[Name]				AS [HQCOName], 
					[HQCO].[Address]			AS [HQCOAddress],
					[HQCO].[City]				AS [HQCOCity], 
					[HQCO].[State]				AS [HQCOState],
					[HQCO].[Zip]				AS [HQCOZip], 
					[INLM_1].[Description]		AS [FromLocation],  
					[MSTD].[TaxDisc]			AS [TaxDisc], 
					[MSIH].[PayTerms]			AS [PayTerms],
					[ARCM].[Address2]			AS [CustomerAddress2], 
					[HQCO].[Country]			AS [HQCOCountry], 
					[ARCM].[BillCountry]		AS [BillCountry], 
					[MSIH].[Country]			AS [Country], 
					[MSIH].[Mth]				AS [Mth], 
					[MSIH].[BatchId]			AS [BatchId], 
					[MSTD].[KeyID]				AS [KeyID],
					[MSTD].[SurchargeKeyID]		AS [SurchargeKeyID],
					[MSTD].[SurchargeCode]		AS [SurchargeCode], 
					[MSIH].[Notes]				AS [Notes],
					[InvoicePrinted] = 'Y',
					[SurchargeSortValue]		= CASE ISNULL(CONVERT(VARCHAR(500),[MSTD].[SurchargeKeyID]),'Parent') WHEN 'Parent' THEN 0 ELSE 1 END,
					[MSIL].[MSTrans]			AS [MSTrans]
		 FROM		[dbo].[HQCO] [HQCO] 
		 INNER JOIN	[dbo].[MSIH] [MSIH] 
				ON	[MSIH].[MSCo]		= [HQCO].[HQCo]
		INNER JOIN	[dbo].[ARCM] [ARCM] 
				ON	[MSIH].[CustGroup]	= [ARCM].[CustGroup] 
				AND [MSIH].[Customer]	= [ARCM].[Customer] 
		LEFT JOIN	[dbo].[MSIL] [MSIL] 
				ON	[MSIH].[MSCo]		= [MSIL].[MSCo] 
				AND [MSIH].[MSInv]		= [MSIL].[MSInv]
		LEFT JOIN	[dbo].[HQPT] [HQPT] 
				ON	[MSIH].[PayTerms]	= [HQPT].[PayTerms]
		LEFT JOIN	[dbo].[MSTD] [MSTD] 
				ON	[MSIL].[MSCo]		= [MSTD].[MSCo]
				AND [MSIL].[MSTrans]	= [MSTD].[MSTrans]
				AND [MSIL].[MSInv]		= [MSTD].[MSInv] 
		INNER JOIN	[dbo].[HQMT] [HQMT] 
				ON	[MSTD].[MatlGroup]	= [HQMT].[MatlGroup]
				AND [MSTD].[Material]	= [HQMT].[Material]
		INNER JOIN	[dbo].[INLM] [INLM_1] 
				ON	[MSTD].[MSCo]		= [INLM_1].[INCo]
				AND [MSTD].[FromLoc]	= [INLM_1].[Loc]
		LEFT JOIN	[dbo].[MSTD] [MSTDSurcharge]
				ON	[MSTDSurcharge].[MSCo]	= [MSTD].[MSCo]
				AND	[MSTDSurcharge].[Mth]	= [MSTD].[Mth]
				AND	[MSTDSurcharge].[KeyID] = [MSTD].[SurchargeKeyID] 
		LEFT JOIN	[dbo].[HQMT] [HQMTSurcharge] 
				ON	[HQMTSurcharge].[MatlGroup]	= [MSTDSurcharge].[MatlGroup]
				AND [HQMTSurcharge].[Material]	= [MSTDSurcharge].[Material]

				
		UNION ALL
-- this selection collects Invoices and supporting details that have not yet been printed
		SELECT		[MatlDescription]			= CASE ISNULL(CONVERT(VARCHAR(500),[MSTD].[SurchargeKeyID]),'Parent') 
													WHEN 'Parent' 
													THEN [HQMT].[Description] 
													ELSE [HQMTSurcharge].[Description] + ' - ' + [HQMT].[Description]
												   END, 
					[ParentMaterial]			=  CASE ISNULL(CONVERT(VARCHAR(500),[MSTD].[SurchargeKeyID]),'Parent') 
													WHEN 'Parent' 
													THEN NULL	
													ELSE [MSTDSurcharge].[Material]
												   END,
					[MSTD].[MatlUnits]			AS [MatlUnits],
					[MSTD].[UnitPrice]			AS [MatlUnitPrice],
					[MSID].[UnitPrice]			AS [MSIDUnitPrice], 
					[MSTD].[ECM]				AS [MatlECM],
					[MSTD].[UM]					AS [MatlUM],
					[MSID].[UM]					AS [MSIDUM], 
					[MSTD].[MatlTotal]			AS [MatlTotal], 
					[MSTD].[TaxCode]			AS [TaxCode], 
					[MSTD].[TaxTotal]			AS [TaxTotal],
					[MSTD].[HaulTotal]			AS [MatlHaulTotal],
					[MSTD].[SaleDate]			AS [MatlSaleDate], 
					[MSID].[SaleDate]			AS [MSIDSaleDate],
					[MSTD].[FromLoc]			AS [MatlFromLoc], 
					[MSID].[FromLoc]			AS [MSIDFromLoc],
					[MSID].[Material]			AS [Material], 
					[MSTD].[Ticket]				AS [Ticket],
					[MSIB].[SepHaul]			AS [SepHaul], 
					[MSIB].[PrintLvl]			AS [InvPrintLvl], 
					[ARCM].[Name]				AS [CustomerName], 
					[MSIB].[MSInv]				AS [MSInv], 
					[MSIB].[InvDate]			AS [InvDate], 
					[ARCM].[BillAddress]		AS [BillAddress], 
					[ARCM].[BillCity]			AS [BillCity], 
					[ARCM].[BillState]			AS [BillState], 
					[ARCM].[BillZip]			AS [BillZip], 
					[ARCM].[BillAddress2]		AS [BillAddress2], 
					[MSIB].[ShipAddress2]		AS [ShipAddress2], 
					[MSIB].[City]				AS [ShipCity],
					[MSIB].[State]				AS [ShipState], 
					[MSIB].[Zip]				AS [ShipZip], 
					[MSIB].[ShipAddress]		AS [ShipAddress], 
					[MSIB].[Customer]			AS [ShipCustomer], 
					[MSIB].[Void]				AS [Void], 
					[ARCM].[SortName]			AS [CustomerSortName], 
					[MSIB].[Co]					AS [Co], 
					[MSIB].[SubtotalLvl]		AS [InvSubtotalLvl], 
					[MSTD].[CustPO]				AS [CustPO],
					[MSIB].[CustPO]				AS [MSIBCustPO],
					[MSID].[CustPO]				AS [MSIDCustPO],
					[MSTD].[CustJob]			AS [CustJob],
					[MSIB].[CustJob]			AS [MSIBCustJob],
					[MSID].[CustJob]			AS [MSIDCustJob], 
					[HQPT].[Description]		AS [HQPTDescription], 
					[MSTD].[DiscOff]			AS [DiscOff], 
					[MSIB].[DiscDate]			AS [DiscDate], 
					[MSIB].[PaymentType]		AS [PaymentType], 
					[MSTD].[CheckNo]			AS [CheckNo], 
					[HQCO].[Name]				AS [HQCOName], 
					[HQCO].[Address]			AS [HQCOAddress],
					[HQCO].[City]				AS [HQCOCity], 
					[HQCO].[State]				AS [HQCOState], 
					[HQCO].[Zip]				AS [HQCOZip], 
					[INLM_FromLoc].[Description] AS [FromLocation],  
					[MSTD].[TaxDisc]			AS [TaxDisc], 
					[MSIB].[PayTerms]			AS [PayTerms],
					[ARCM].[Address2]			AS [CustomerAddress2], 
					[HQCO].[Country]			AS [HQCOCountry], 
					[ARCM].[BillCountry]		AS [BillCountry], 
					[MSIB].[Country]			AS [Country], 
					[MSIB].[Mth]				AS [Mth], 
					[MSIB].[BatchId]			AS [BatchId], 
					[MSTD].[KeyID]				AS [KeyID],
					[MSTD].[SurchargeKeyID]		AS [SurchargeKeyID], 
					[MSTD].[SurchargeCode]		AS [SurchargeCode],
					[MSIB].[Notes]				AS [Notes],
					[InvoicePrinted]	= 'N',
					[SurchargeSortValue] = CASE ISNULL(CONVERT(VARCHAR(500),[MSTD].[SurchargeKeyID]),'Parent') WHEN 'Parent' THEN 0 ELSE 1 END,
					[MSID].[MSTrans]			AS [MSTrans]
		FROM		[dbo].[HQCO] [HQCO] 
		INNER JOIN  [dbo].[MSIB] [MSIB] 
				ON	[HQCO].[HQCo]		= [MSIB].[Co]
		INNER JOIN	[dbo].[ARCM] [ARCM] 
				ON	[MSIB].[CustGroup]	= [ARCM].[CustGroup] 
				AND [MSIB].[Customer]	= [ARCM].[Customer]
		LEFT JOIN	[dbo].[MSID] [MSID] 
				ON	[MSIB].[Co]			= [MSID].[Co]
				AND [MSIB].[Mth]		= [MSID].[Mth] 
				AND [MSIB].[BatchId]	= [MSID].[BatchId] 
				AND [MSIB].[BatchSeq]	= [MSID].[BatchSeq] 
		LEFT JOIN	[dbo].[HQPT] [HQPT] 
				ON	[MSIB].[PayTerms]	= [HQPT].[PayTerms] 
		LEFT JOIN	[dbo].[MSTD] [MSTD] 
				ON  [MSID].[Co]			= [MSTD].[MSCo]
				AND [MSID].[Mth]		= [MSTD].[Mth] 
				AND [MSID].[MSTrans]	= [MSTD].[MSTrans] 
		INNER JOIN	[dbo].[HQMT] [HQMT] 
				ON	[MSTD].[MatlGroup]	= [HQMT].[MatlGroup]
				AND [MSTD].[Material]	= [HQMT].[Material] 
		INNER JOIN	[dbo].[INLM] [INLM_FromLoc] 
				ON	[MSTD].[MSCo]		= [INLM_FromLoc].[INCo]
				AND [MSTD].[FromLoc]	= [INLM_FromLoc].[Loc]
		LEFT JOIN	[dbo].[MSTD] [MSTDSurcharge]
				ON	[MSTDSurcharge].[MSCo]		= [MSTD].[MSCo]
				AND	[MSTDSurcharge].[Mth]		= [MSTD].[Mth]
				AND	[MSTDSurcharge].[KeyID]		= [MSTD].[SurchargeKeyID] 
		LEFT JOIN	[dbo].[HQMT] [HQMTSurcharge] 
				ON	[HQMTSurcharge].[MatlGroup]	= [MSTDSurcharge].[MatlGroup]
				AND [HQMTSurcharge].[Material]	= [MSTDSurcharge].[Material]



GO
GRANT SELECT ON  [dbo].[vrvMSInvoice] TO [public]
GRANT INSERT ON  [dbo].[vrvMSInvoice] TO [public]
GRANT DELETE ON  [dbo].[vrvMSInvoice] TO [public]
GRANT UPDATE ON  [dbo].[vrvMSInvoice] TO [public]
GO
