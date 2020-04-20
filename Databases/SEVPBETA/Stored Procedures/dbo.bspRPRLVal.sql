SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspRPRLVal    Script Date: 8/28/99 9:35:43 AM ******/
   /****** Object:  Stored Procedure dbo.bspRPRLVal    Script Date: 3/28/99 12:00:39 AM ******/
   CREATE  proc [dbo].[bspRPRLVal]
   /***********************************************************
    * CREATED BY: JE   1/2/97
    * MODIFIED By : JE 1/2/97
    * MODIFIED By TL 1/25/06 for use VP6
    *				HH 6/4/12 TK-15179 extended field for RPRL.Loc to varchar(50)
    *				DK 06/26/12 TK-15495 - add param and extend to prevent changing To server / To instance for RSS types
    * USAGE:
    *   validates RP Report Location 
    *   pass in Location
    *   returns Path & ErrMsg if any
    * 
   
    * OUTPUT PARAMETERS
    *   @msg     Error message if invalid, 
    * RETURN VALUE
    *   0 Success
    *   1 fail
    *****************************************************/ 
   
   	@ToLocation varchar(50) = null, 
   	@FromLocation VARCHAR(50),
   	@msg varchar(60) output
   	
   as
   set nocount on
   declare @rcode int
   
   
   select @rcode = 0
   
   if @ToLocation is null
   	begin
   	select @msg = 'Missing Location!', @rcode = 1
   	goto bspexit
   	end
   	ELSE 

	IF (SELECT LocType FROM RPRL WHERE Location = @FromLocation) = 'URL'
	BEGIN
		DECLARE @FromServer AS TABLE (Server VARCHAR(255), ReportServerInstance VARCHAR(255))
		DECLARE @ToServer AS TABLE (Server VARCHAR(255), ReportServerInstance VARCHAR(255))
				
		INSERT INTO	@FromServer (Server, ReportServerInstance)
		SELECT		Server					= S.Server,
					ReportServerInstance	= S.ReportServerInstance
		FROM		RPRL L
		INNER JOIN	RPRSServer S
				ON	S.ServerName	= L.ServerName 
				AND L.Location		= @FromLocation
		
		INSERT INTO	@ToServer (Server, ReportServerInstance)
		SELECT		Server					= S.Server,
					ReportServerInstance	= S.ReportServerInstance
		FROM		RPRL L
		INNER JOIN	RPRSServer S
				ON	S.ServerName	= L.ServerName 
				AND L.Location		= @ToLocation
				
		IF (SELECT Server FROM @FromServer) <> (SELECT Server FROM @ToServer)
		BEGIN 
			SELECT @msg = 'Cannot copy to a different server!', @rcode = 1
			goto bspexit 
		END 
		
		IF (SELECT ReportServerInstance FROM @FromServer) <> (SELECT ReportServerInstance FROM @ToServer)
		BEGIN 
			SELECT @msg = 'Cannot copy to a different instance of Reporting Services!', @rcode = 1
			goto bspexit 
		END 
	END 
   
   /* check for Location */
   	select @msg = Path from dbo.RPRL where Location = @ToLocation
   
   if @msg is null
   	begin
   	    select @msg = 'Location has an invalid path' , @rcode = 1
   
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspRPRLVal] TO [public]
GO
