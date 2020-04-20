SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[brvHQATTrans] as select HQCo, TransType=Left(FormName,2), 
    --TransCo= (case when isnumeric(Substring(KeyField,4,charindex(' ',KeyField)-4))=1
    --		 then Convert(tinyint,Substring(KeyField,4,charindex(' ',KeyField)-4)) else 0 end),
    TransMth=(case when isdate(Substring(KeyField,charindex('Mth',KeyField)+5,8))=1
    		 then Convert(smalldatetime, Substring(KeyField,charindex('Mth',KeyField)+5,8)) else NULL end), 
    Trans=(case when isnumeric(Substring(KeyField,charindex('Trans',KeyField)+6,10))=1
    		then Convert(int,Substring(KeyField,charindex('Trans',KeyField)+6,10)) else 0 end),
    Description, AddedBy, AddDate, DocName
    From HQAT Where KeyField Like '%Trans%'

GO
GRANT SELECT ON  [dbo].[brvHQATTrans] TO [public]
GRANT INSERT ON  [dbo].[brvHQATTrans] TO [public]
GRANT DELETE ON  [dbo].[brvHQATTrans] TO [public]
GRANT UPDATE ON  [dbo].[brvHQATTrans] TO [public]
GRANT SELECT ON  [dbo].[brvHQATTrans] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvHQATTrans] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvHQATTrans] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvHQATTrans] TO [Viewpoint]
GO
