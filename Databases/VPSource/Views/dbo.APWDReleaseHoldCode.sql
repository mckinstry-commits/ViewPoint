SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APWDReleaseHoldCode] as select APCo,Mth,APTrans,UserId,APLine,APSeq, 'N' as 'ReleaseHoldCode' From bAPWD 







GO
GRANT SELECT ON  [dbo].[APWDReleaseHoldCode] TO [public]
GRANT INSERT ON  [dbo].[APWDReleaseHoldCode] TO [public]
GRANT DELETE ON  [dbo].[APWDReleaseHoldCode] TO [public]
GRANT UPDATE ON  [dbo].[APWDReleaseHoldCode] TO [public]
GO
