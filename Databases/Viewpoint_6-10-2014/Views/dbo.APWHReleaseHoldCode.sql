SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APWHReleaseHoldCode] as select APCo,Mth,APTrans,UserId,'N' as 'ReleaseHoldCode' From bAPWH 






GO
GRANT SELECT ON  [dbo].[APWHReleaseHoldCode] TO [public]
GRANT INSERT ON  [dbo].[APWHReleaseHoldCode] TO [public]
GRANT DELETE ON  [dbo].[APWHReleaseHoldCode] TO [public]
GRANT UPDATE ON  [dbo].[APWHReleaseHoldCode] TO [public]
GRANT SELECT ON  [dbo].[APWHReleaseHoldCode] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APWHReleaseHoldCode] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APWHReleaseHoldCode] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APWHReleaseHoldCode] TO [Viewpoint]
GO
