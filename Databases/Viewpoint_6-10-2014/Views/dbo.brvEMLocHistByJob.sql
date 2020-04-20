SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  View [dbo].[brvEMLocHistByJob]
    
    /***********************************************
      EM Location History By Job View 
      Created 2/5/2002 DH
    
     View performs two separate select statements for both the
     FromJob and ToJob information.  This allows reports
     to provide both the starting and ending location transfer
     information under a single Job.  
    
    Reports:  EM Location History By Job
    
    *************************************************/
    
    as
    
    --Select To Job information
    
    select EMCo, JCCo=ToJCCo, Job=ToJob, Month, Trans, BatchID, Equipment, FromJCCo, FromJob, ToJCCo, ToJob, FromLocation, ToLocation,
    DateIn, TimeIn, DateOut, TimeOut, Memo, EstOut, InUseBatchID From EMLH
    
    union all
    
    --Select From Job information
    
    select EMCo, FromJCCo, FromJob, Month, Trans, BatchID, Equipment, FromJCCo, FromJob, ToJCCo, ToJob, FromLocation, ToLocation,
    DateIn, TimeIn, DateOut, TimeOut, Memo, EstOut, InUseBatchID From EMLH

GO
GRANT SELECT ON  [dbo].[brvEMLocHistByJob] TO [public]
GRANT INSERT ON  [dbo].[brvEMLocHistByJob] TO [public]
GRANT DELETE ON  [dbo].[brvEMLocHistByJob] TO [public]
GRANT UPDATE ON  [dbo].[brvEMLocHistByJob] TO [public]
GRANT SELECT ON  [dbo].[brvEMLocHistByJob] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvEMLocHistByJob] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvEMLocHistByJob] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvEMLocHistByJob] TO [Viewpoint]
GO
