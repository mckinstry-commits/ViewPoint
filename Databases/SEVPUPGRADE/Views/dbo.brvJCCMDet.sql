SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    view [dbo].[brvJCCMDet] as 
---------------------------------
-- Created: ??
-- Modified: GG 07/30/07 - correct reference to DDDTShared for V6
--
-- Used: ??
--
----------------------------------

select j.*, d.Secure 
From dbo.JCCM j (nolock)
Left Join dbo.DDDTShared d with (nolock) on Datatype = 'bJob'

GO
GRANT SELECT ON  [dbo].[brvJCCMDet] TO [public]
GRANT INSERT ON  [dbo].[brvJCCMDet] TO [public]
GRANT DELETE ON  [dbo].[brvJCCMDet] TO [public]
GRANT UPDATE ON  [dbo].[brvJCCMDet] TO [public]
GO
