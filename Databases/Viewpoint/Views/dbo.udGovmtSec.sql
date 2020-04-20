SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udGovmtSec] as select a.* From budGovmtSec a
GO
GRANT SELECT ON  [dbo].[udGovmtSec] TO [public]
GRANT INSERT ON  [dbo].[udGovmtSec] TO [public]
GRANT DELETE ON  [dbo].[udGovmtSec] TO [public]
GRANT UPDATE ON  [dbo].[udGovmtSec] TO [public]
GO
