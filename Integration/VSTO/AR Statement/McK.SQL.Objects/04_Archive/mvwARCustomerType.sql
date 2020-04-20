USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='mvwARCustomerType' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='VIEW' )
Begin
	Print 'DROP VIEW dbo.mvwARCustomerType'
	DROP VIEW dbo.mvwARCustomerType
End
GO

Print 'CREATE VIEW dbo.mvwARCustomerType'
GO


CREATE VIEW [dbo].mvwARCustomerType
/*******************************************************************************
Project:	AR Invoice Report Enhancements
Author:		Chris Lounsbury, Business Information Group

Purpose:	Determine the customer type based on unique business criteria

Change Log:

	20190228	LG -  made 0250 & 0251 responsibility of C – Corporate
	20190109	CRL	Initial Development
*******************************************************************************/
AS

	WITH ContractWork
	AS
	(
		-- Customers with Corporate Work
		SELECT	DISTINCT
				th.CustGroup,
				th.Customer
		FROM	ARTH AS th
		JOIN	ARTL AS tl
			ON	th.ARCo = tl.ARCo
			AND th.Mth = tl.Mth
			AND th.ARTrans = tl.ARTrans
		JOIN	ARCM AS cm
			ON	th.CustGroup = cm.CustGroup
			AND th.Customer = cm.Customer
		JOIN dbo.JCCM AS jcm
			ON	th.JCCo	= jcm.JCCo 
			AND th.Contract= jcm.Contract 
		JOIN dbo.bJCDM AS jdm
			ON	jdm.JCCo = jcm.JCCo
			AND jdm.Department = jcm.Department
		WHERE	th.Invoiced <> th.Paid
			AND COALESCE(jdm.udGLDept, '') NOT IN ('0230', '0520', '0521', '0522') 

			-- Report filters, remove
			--AND tl.RecType BETWEEN 0 AND 255
			--AND cm.StmtType= 'O' 
			--AND cm.StmntPrint= 'Y' 
			--AND th.Customer BETWEEN 0 AND 999999
			--AND th.ARCo = 1 
			--AND th.TransDate <= '2019-01-10 00:00:00'
	),
	--ServiceWorkCorp
	--AS
	--(
	--	-- Customers with Service Work
	--	-- Job-based service work
	--	SELECT	DISTINCT
	--			th.CustGroup,
	--			th.Customer
	--	FROM	ARTH AS th
	--	JOIN	ARTL AS tl
	--		ON	th.ARCo = tl.ARCo
	--		AND th.Mth = tl.Mth
	--		AND th.ARTrans = tl.ARTrans
	--	JOIN	ARCM AS cm
	--		ON	th.CustGroup = cm.CustGroup
	--		AND th.Customer = cm.Customer
	--	JOIN	dbo.JCCM AS jcm
	--		ON	th.JCCo	= jcm.JCCo 
	--		AND th.Contract= jcm.Contract 
	--	JOIN dbo.bJCDM AS jdm
	--		ON	jdm.JCCo = jcm.JCCo
	--		AND jdm.Department = jcm.Department
	--	WHERE	th.Invoiced <> th.Paid
	--		AND COALESCE(jdm.udGLDept, '') IN ('0250', '0251')

	--	UNION ALL 

	--	-- Service-based Service work
	--	SELECT	DISTINCT
	--			th.CustGroup,
	--			th.Customer
	--	FROM	bARTH AS th 
	--	JOIN	bARTL AS tl
	--		ON	th.ARCo = tl.ARCo
	--		AND th.Mth = tl.Mth	
	--		AND th.ARTrans = tl.ARTrans
	--	JOIN	ARCM AS cm
	--		ON	th.CustGroup = cm.CustGroup
	--		AND th.Customer = cm.Customer
	--	JOIN	vSMInvoice AS smi
	--		ON	smi.ARCo = th.ARCo
	--		AND smi.ARPostedMth = th.Mth
	--		AND smi.ARTrans = th.ARTrans
	--	JOIN	vSMInvoiceDetail AS smid
	--		ON	smi.SMCo = smid.SMCo
	--		AND smi.Invoice = smid.Invoice
	--		AND smid.InvoiceDetail = tl.ARLine
	--	LEFT JOIN vSMWorkOrder AS wo
	--		ON	smid.SMCo = wo.SMCo
	--		AND smid.WorkOrder = wo.WorkOrder
	--	LEFT JOIN vSMServiceCenter AS sc
	--		ON	sc.SMCo = wo.SMCo
	--		AND sc.ServiceCenter = wo.ServiceCenter
	--	LEFT JOIN vSMDepartment AS dep
	--		ON	dep.SMCo = sc.SMCo
	--		AND dep.Department = sc.Department
	--	WHERE	th.Invoiced <> th.Paid
	--		AND COALESCE(dep.udGLDept, '') IN ('0250', '0251')
	--),
	ServiceWork
	AS
	(
		-- Customers with Service Work
		-- Job-based service work
		SELECT	DISTINCT
				th.CustGroup,
				th.Customer
		FROM	ARTH AS th
		JOIN	ARTL AS tl
			ON	th.ARCo = tl.ARCo
			AND th.Mth = tl.Mth
			AND th.ARTrans = tl.ARTrans
		JOIN	ARCM AS cm
			ON	th.CustGroup = cm.CustGroup
			AND th.Customer = cm.Customer
		JOIN	dbo.JCCM AS jcm
			ON	th.JCCo	= jcm.JCCo 
			AND th.Contract= jcm.Contract 
		JOIN dbo.bJCDM AS jdm
			ON	jdm.JCCo = jcm.JCCo
			AND jdm.Department = jcm.Department
		WHERE	th.Invoiced <> th.Paid
			AND COALESCE(jdm.udGLDept, '') IN ('0230', '0520', '0521', '0522')

		UNION ALL 

		-- Service-based Service work
		SELECT	DISTINCT
				th.CustGroup,
				th.Customer
		FROM	bARTH AS th 
		JOIN	bARTL AS tl
			ON	th.ARCo = tl.ARCo
			AND th.Mth = tl.Mth	
			AND th.ARTrans = tl.ARTrans
		JOIN	ARCM AS cm
			ON	th.CustGroup = cm.CustGroup
			AND th.Customer = cm.Customer
		JOIN	vSMInvoice AS smi
			ON	smi.ARCo = th.ARCo
			AND smi.ARPostedMth = th.Mth
			AND smi.ARTrans = th.ARTrans
		JOIN	vSMInvoiceDetail AS smid
			ON	smi.SMCo = smid.SMCo
			AND smi.Invoice = smid.Invoice
			AND smid.InvoiceDetail = tl.ARLine
		LEFT JOIN vSMWorkOrder AS wo
			ON	smid.SMCo = wo.SMCo
			AND smid.WorkOrder = wo.WorkOrder
		LEFT JOIN vSMServiceCenter AS sc
			ON	sc.SMCo = wo.SMCo
			AND sc.ServiceCenter = wo.ServiceCenter
		LEFT JOIN vSMDepartment AS dep
			ON	dep.SMCo = sc.SMCo
			AND dep.Department = sc.Department
		WHERE	th.Invoiced <> th.Paid
			AND COALESCE(dep.udGLDept, '') IN ('0230', '0520', '0521', '0522') 
	)

	SELECT	cm.CustGroup,
			cm.Customer,
			CustomerType = CASE WHEN (cw.Customer IS NOT NULL AND sw.Customer IS NULL) THEN 'C'
								WHEN cw.Customer IS NULL AND sw.Customer IS NOT NULL THEN 'S'
								WHEN cw.Customer IS NOT NULL AND sw.Customer IS NOT NULL THEN 'B'
								ELSE 'S' -- ASTEA CONVERTED WOs
								END
	FROM	bARCM AS cm
	LEFT JOIN ContractWork AS cw
		ON	cw.CustGroup = cm.CustGroup
		AND cw.Customer = cm.Customer
	LEFT JOIN ServiceWork AS sw
		ON	sw.CustGroup = cm.CustGroup
		AND sw.Customer = cm.Customer
	--LEFT JOIN ServiceWorkCorp AS sc
	--	ON	sc.CustGroup = cm.CustGroup
	--	AND sc.Customer = cm.Customer

GO

Grant SELECT ON dbo.mvwARCustomerType TO [MCKINSTRY\Viewpoint Users]
