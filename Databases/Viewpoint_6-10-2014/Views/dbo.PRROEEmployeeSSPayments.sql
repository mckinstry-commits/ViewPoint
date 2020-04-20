SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[PRROEEmployeeSSPayments] as select a.* From vPRROEEmployeeSSPayments a

GO
GRANT SELECT ON  [dbo].[PRROEEmployeeSSPayments] TO [public]
GRANT INSERT ON  [dbo].[PRROEEmployeeSSPayments] TO [public]
GRANT DELETE ON  [dbo].[PRROEEmployeeSSPayments] TO [public]
GRANT UPDATE ON  [dbo].[PRROEEmployeeSSPayments] TO [public]
GRANT SELECT ON  [dbo].[PRROEEmployeeSSPayments] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRROEEmployeeSSPayments] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRROEEmployeeSSPayments] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRROEEmployeeSSPayments] TO [Viewpoint]
GO
