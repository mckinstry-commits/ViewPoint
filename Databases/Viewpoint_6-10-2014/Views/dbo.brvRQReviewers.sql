SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[brvRQReviewers] 
   as
   select Type = '1', RQCo, Reviewer, RQID, RQLine, Quote = NULL, QuoteLine = NULL, 
           AssignedDate,ReviewDate, Status, RejReason = Description, Notes
   from RQRR
   
   
   UNION ALL
   
   select Type = '2', RQCo, Reviewer,NULL, NULL, Quote, QuoteLine, 
          AssignedDate, ReviewDate, Status, Description, Notes
   from RQQR

GO
GRANT SELECT ON  [dbo].[brvRQReviewers] TO [public]
GRANT INSERT ON  [dbo].[brvRQReviewers] TO [public]
GRANT DELETE ON  [dbo].[brvRQReviewers] TO [public]
GRANT UPDATE ON  [dbo].[brvRQReviewers] TO [public]
GRANT SELECT ON  [dbo].[brvRQReviewers] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvRQReviewers] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvRQReviewers] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvRQReviewers] TO [Viewpoint]
GO
