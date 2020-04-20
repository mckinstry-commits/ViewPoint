SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

Create View [dbo].[SMWorkCompletedARTL]

/*==================================================================================          
    
Author:       
ScottAlvey      
    
Create date:       
04/12/2012       
    
Usage:
Do the change in how tax in AR and invoices in SM interact (B-08702 - Edit Taxes on SM Invoice)
many SM tables\views related to Invoices, Work Completed, and AR Records had to be mondified.
Instead of holding the references to the AR records in the Invoice or Work Completed tables
it was decied to create a new table called vSMWorkCompletedARTL which uses the field of
SMWorkCompletedARTLID to link back to the various SM tables. We just need to create
a view on this table so that reports can pick it up.        
     
Revision History          
Date  Author  Issue     Description    
    
==================================================================================*/    

as

select a.* From vSMWorkCompletedARTL a  
GO
GRANT SELECT ON  [dbo].[SMWorkCompletedARTL] TO [public]
GRANT INSERT ON  [dbo].[SMWorkCompletedARTL] TO [public]
GRANT DELETE ON  [dbo].[SMWorkCompletedARTL] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkCompletedARTL] TO [public]
GO
