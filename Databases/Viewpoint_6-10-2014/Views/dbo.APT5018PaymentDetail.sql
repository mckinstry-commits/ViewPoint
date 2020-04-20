SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[APT5018PaymentDetail] 
AS 
SELECT a.* FROM vAPT5018PaymentDetail a



GO
GRANT SELECT ON  [dbo].[APT5018PaymentDetail] TO [public]
GRANT INSERT ON  [dbo].[APT5018PaymentDetail] TO [public]
GRANT DELETE ON  [dbo].[APT5018PaymentDetail] TO [public]
GRANT UPDATE ON  [dbo].[APT5018PaymentDetail] TO [public]
GRANT SELECT ON  [dbo].[APT5018PaymentDetail] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APT5018PaymentDetail] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APT5018PaymentDetail] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APT5018PaymentDetail] TO [Viewpoint]
GO
