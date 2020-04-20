CREATE TABLE [dbo].[vSLWIInvoices]
(
[SLCo] [dbo].[bCompany] NOT NULL,
[Line] [smallint] NOT NULL,
[UIMth] [dbo].[bMonth] NOT NULL,
[UISeq] [smallint] NOT NULL,
[APULKeyID] [bigint] NOT NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[SLItem] [dbo].[bItem] NULL,
[Description] [dbo].[bItemDesc] NULL,
[UM] [dbo].[bUM] NULL,
[Units] [dbo].[bUnits] NULL,
[UnitCost] [dbo].[bUnitCost] NOT NULL,
[ECM] [dbo].[bECM] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Supplier] [dbo].[bVendor] NULL,
[PayType] [tinyint] NULL,
[GrossAmt] [dbo].[bDollar] NOT NULL,
[MiscAmt] [dbo].[bDollar] NOT NULL,
[MiscYN] [dbo].[bYN] NOT NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxBasis] [dbo].[bDollar] NOT NULL,
[TaxAmt] [dbo].[bDollar] NOT NULL,
[Retainage] [dbo].[bDollar] NOT NULL,
[Discount] [dbo].[bDollar] NOT NULL,
[PayCategory] [int] NULL,
[InvOriginator] [dbo].[bVPUserName] NULL,
[SLDetailKeyID] [bigint] NULL,
[SLKeyID] [bigint] NULL,
[SkipClearId] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vSLWIInvoices_SkipClearId] DEFAULT ('N')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   
   CREATE   TRIGGER [dbo].[vtSLWIInvoicesd] ON [dbo].[vSLWIInvoices] FOR DELETE AS    
/*-----------------------------------------------------------------
    *Created:  	DC  03/16/2009
    *			
    *
    * Delete trigger for vSLWIInvoices:
    *	-Updates the associated APUL records and clears the SLKeyID column.
	*
    */----------------------------------------------------------------
    DECLARE @errmsg varchar(255), @numrows int
    	
	DECLARE @iNextRowId int,
			@iCurrentRowId int,
			@iLoopControl int
	     
	--Table variable to process multiple deletes
	DECLARE @SLWIInvoices_temp TABLE (apulkeyid bigint,
		skipclearid varchar(1))		    
    
    SELECT @numrows = @@rowcount 
    SELECT @iLoopControl = 0, @iCurrentRowId = 0, @iNextRowId = 0 
    IF @numrows = 0 return   
    
    SET NOCOUNT ON      
        
    IF @numrows = 1
		BEGIN
		IF (select SkipClearId from Deleted) = 'N'
			BEGIN
			UPDATE APUL
			SET SLKeyID = NULL
			FROM APUL l 
			Join Deleted d on d.APULKeyID = l.KeyID       				
			END		
		END
	ELSE
		BEGIN		
		--Insert records into @SLWI_temp table
		INSERT INTO @SLWIInvoices_temp(apulkeyid, skipclearid) 
		select APULKeyID, SkipClearId
		from Deleted
   			  		   		
		--Get keyid to loop through SLWI_temp table   			  		   						
		SELECT @iNextRowId = MIN(apulkeyid)
		FROM   @SLWIInvoices_temp
				
		IF ISNULL(@iNextRowId,0) = 0
			--no SLWI records for the subcontract.
			BEGIN			  
			SELECT @iLoopControl = 1			
			END				
				
		WHILE @iLoopControl = 0  -- start the main processing loop.
			BEGIN
			
			SELECT @iCurrentRowId = @iNextRowId
						
			IF (select skipclearid from @SLWIInvoices_temp where apulkeyid = @iNextRowId) = 'N'
				BEGIN
				UPDATE APUL
				SET SLKeyID = NULL
				FROM APUL l 
				where l.KeyID = @iNextRowId
				END
			
			-- Reset looping variables.           
			SELECT @iNextRowId = NULL
			          
			-- get the next iRowId
			SELECT @iNextRowId = MIN(apulkeyid)
			FROM @SLWIInvoices_temp
			WHERE apulkeyid > @iCurrentRowId

			-- did we get a valid next row id?
			IF ISNULL(@iNextRowId,0) = 0
				BEGIN
				SELECT @iLoopControl = 1
				END				
			END				
		END


    RETURN
    
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [viKeyID] ON [dbo].[vSLWIInvoices] ([APULKeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [viSLWIInvoices] ON [dbo].[vSLWIInvoices] ([SLCo], [UIMth], [UISeq], [Line]) ON [PRIMARY]
GO
