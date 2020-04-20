SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[brvPOAudit] as SELECT POHB.Co, POHB.Mth, POHB.BatchId, POHB.BatchSeq,POHB.PO,
    	POIB.POItem
    	FROM POIB
    	Left Outer JOIN POHB on POIB.Co=POHB.Co and POIB.Mth=POHB.Mth and
    	POIB.BatchId=POHB.BatchId and POIB.BatchSeq=POHB.BatchSeq

GO
GRANT SELECT ON  [dbo].[brvPOAudit] TO [public]
GRANT INSERT ON  [dbo].[brvPOAudit] TO [public]
GRANT DELETE ON  [dbo].[brvPOAudit] TO [public]
GRANT UPDATE ON  [dbo].[brvPOAudit] TO [public]
GO
