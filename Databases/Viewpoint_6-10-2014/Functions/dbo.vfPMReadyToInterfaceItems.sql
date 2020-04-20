SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =============================================
-- Author:		AW vfPMReadyToInterfaceItems
-- Modified: 		TFS 42706 added another level to drill down query

-- Create date: 1/31/2013
-- Description:	Returns the PM Records Ready To Interface Items
--   Used in Work Center inquery to drill down to the related items for the given record
--
-- Forms Accepted / Query results returned
-- PMProjects -- All related form headers
-- PMACOS -- ACO Items / all related header records
-- PMPOHeader -- PO Items  / all related header records
-- PMPOCO -- POCO Items / all related header records
-- PMSLHeader -- SL Items / all related header records
-- PMSubcontractCO -- SubCo Items / all related header records
-- PMMOHeader -- MO Items / all related header records
-- PMMSQuote -- Quote Items / all related header records
--
--
-- =============================================
CREATE FUNCTION dbo.vfPMReadyToInterfaceItems(@Form varchar(30), @keyid bigint)
RETURNS @readyToInterfaceItems TABLE 
(
    -- Columns returned by the function
	PMCo bCompany NOT NULL,
    Project bJob NOT NULL,
	JobStatus tinyint NOT NULL,
	ProjectMgr bigint, 
	Interface varchar(30) NOT NULL,
	ID varchar(30),
	CO int,
	ACO varchar(30),
	Item varchar(10),
	[Description] varchar (120),
	Amount decimal(18,2),
	InterfacedYN varchar(10) NULL,
	Form varchar(30),
	KeyID bigint
)
AS 

BEGIN

	INSERT @readyToInterfaceItems(PMCo,JobStatus,ProjectMgr,Project,Interface, Description, ID, CO, ACO, Item, InterfacedYN, Amount, Form, KeyID)
	SELECT PMCo,JobStatus,ProjectMgr,Project,Interface, Description, ID, CO, ACO, Item, InterfacedYN, Amount, Form, KeyID
		FROM dbo.vfPMReadyToInterfaceProject(@Form,@keyid) j
	UNION ALL
	SELECT PMCo,JobStatus,ProjectMgr,Project,Interface, Description, ID, CO, ACO, Item,  InterfacedYN, Amount, Form, KeyID
		FROM dbo.vfPMReadyToInterfaceACO(@Form,@keyid) j
	UNION ALL
	SELECT PMCo,JobStatus,ProjectMgr,Project,Interface, Description, ID, CO, ACO, Item,  InterfacedYN, Amount, Form, KeyID
		FROM dbo.vfPMReadyToInterfacePO(@Form,@keyid) j
	UNION ALL
	SELECT PMCo,JobStatus,ProjectMgr,Project,Interface, Description, ID, CO, ACO, Item,  InterfacedYN, Amount, Form, KeyID
		FROM dbo.vfPMReadyToInterfacePOCO(@Form,@keyid) j
	UNION ALL
	SELECT PMCo,JobStatus,ProjectMgr,Project,Interface, Description, ID, CO, ACO, Item,  InterfacedYN, Amount, Form, KeyID
		FROM dbo.vfPMReadyToInterfaceMO(@Form,@keyid) j
	UNION ALL
	SELECT PMCo,JobStatus,ProjectMgr,Project,Interface, Description, ID, CO, ACO, Item,  InterfacedYN, Amount, Form, KeyID
		FROM dbo.vfPMReadyToInterfaceMSQuote(@Form,@keyid) j
	UNION ALL
	SELECT PMCo,JobStatus,ProjectMgr,Project,Interface, Description, ID, CO, ACO, Item,  InterfacedYN, Amount, Form, KeyID
		FROM dbo.vfPMReadyToInterfaceSL(@Form,@keyid) j
	UNION ALL
	SELECT PMCo,JobStatus,ProjectMgr,Project,Interface, Description, ID, CO, ACO, Item,  InterfacedYN, Amount, Form, KeyID
		FROM dbo.vfPMReadyToInterfaceSUBCO(@Form,@keyid) j
RETURN
END
GO
GRANT SELECT ON  [dbo].[vfPMReadyToInterfaceItems] TO [public]
GO
