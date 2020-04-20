SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*****************************************
   * Created By: DAN SO 04/13/2011
   * Modfied By:
   *
   * Provides a view of PM Material Detail
   * used in lookups for distinct PMMF.POCONum's
   *
   * (copied from PMSLSubCoLookup)
   *
   *****************************************/
    

	CREATE VIEW [dbo].[PMMFPOCONumLookup] AS
		SELECT	cd.POCo, cd.PO, cd.POCONum, it.Description
		  FROM	dbo.POCD cd
	INNER JOIN	dbo.POIT it ON cd.POCo=it.POCo AND it.PO=cd.PO AND it.POItem=cd.POItem
		 WHERE	cd.POCONum IS NOT NULL AND cd.POCONum <> 0
	  GROUP BY	cd.POCo, cd.PO, cd.POCONum, it.Description
	  
		 UNION
		
		SELECT	mf.POCo, mf.PO, mf.POCONum, mf.MtlDescription
		  FROM	dbo.PMMF mf 
		 WHERE	NOT EXISTS(SELECT TOP 1 1 
							 FROM dbo.POCD oc 
							WHERE mf.POCo=oc.POCo AND mf.PO=oc.PO AND mf.POCONum=oc.POCONum)
		   AND	mf.PO IS NOT NULL AND mf.POCONum IS NOT NULL AND mf.POCONum <> 0
	  GROUP BY	mf.POCo, mf.PO, mf.POCONum, mf.MtlDescription



GO
GRANT SELECT ON  [dbo].[PMMFPOCONumLookup] TO [public]
GRANT INSERT ON  [dbo].[PMMFPOCONumLookup] TO [public]
GRANT DELETE ON  [dbo].[PMMFPOCONumLookup] TO [public]
GRANT UPDATE ON  [dbo].[PMMFPOCONumLookup] TO [public]
GO
