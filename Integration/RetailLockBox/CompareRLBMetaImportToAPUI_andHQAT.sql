/****** Script for SelectTopNRows command from SSMS  ******/
SELECT 
		apui.UIMth
      ,apui.UISeq
	  ,apui.InvTotal
	  ,rlb.[MetaFileName]
      ,rlb.[RecordType]
      ,rlb.[Company]
      ,rlb.[Number]
      ,rlb.[VendorGroup]
      ,rlb.[Vendor]
      ,rlb.[VendorName]
      ,rlb.[TransactionDate]
      ,rlb.[JCCo]
      ,rlb.[Job]
      ,rlb.[JobDescription]
      ,rlb.[Description]
      ,rlb.[DetailLineCount]
      ,rlb.[TotalOrigCost]
      ,rlb.[TotalOrigTax]
      ,rlb.[RemainingAmount]
      ,rlb.[RemainingTax]
      ,rlb.[CollectedInvoiceDate]
      ,rlb.[CollectedInvoiceNumber]
      ,rlb.[CollectedTaxAmount]
      ,rlb.[CollectedShippingAmount]
      ,rlb.[CollectedInvoiceAmount]
      ,rlb.[CollectedImage]
	  ,hqat.AttachmentID
	  ,hqat.DocName
  FROM [MCK_INTEGRATION].[dbo].[RLB_AP_ImportData] rlb LEFT OUTER JOIN
		Viewpoint.dbo.APUI apui ON
			rlb.VendorGroup=apui.VendorGroup
		AND	rlb.Vendor=apui.Vendor
		AND rlb.CollectedInvoiceNumber=apui.APRef 
		AND rlb.CollectedInvoiceAmount=apui.InvTotal LEFT OUTER JOIN
		Viewpoint.dbo.HQAT hqat ON
			hqat.DocName LIKE '%' + SUBSTRING(rlb.CollectedImage,CHARINDEX('\',rlb.CollectedImage)+1,LEN(rlb.CollectedImage)-CHARINDEX('\',rlb.CollectedImage)) + '%'


