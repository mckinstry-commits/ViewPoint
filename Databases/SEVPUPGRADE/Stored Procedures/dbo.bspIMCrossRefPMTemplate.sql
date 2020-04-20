SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspIMCrossRefPMTemplate    Script Date: 11/6/2002 9:30:31 AM ******/
   
   
   
   CREATE           procedure [dbo].[bspIMCrossRefPMTemplate]
    /************************************************************************
    * CREATED:    DANF 01/22/02
    * MODIFIED:
    *
    * Purpose of Stored Procedure
    *
    *    Apply cross references set up in PMUX
    *    to IMWE
    *
    *
    * Notes about Stored Procedure because PM the cross reference is based on groups
    * such as VendorGroups, PhaseGroups, and MatlGroups pm cross references are applied after
    * Bidtek Defauls.
    *
    *
    * returns 0 if successfull
    * returns 1 and error msg if failed
    *
    *************************************************************************/
   
        (@importtemplate varchar(20), @importid varchar(10), @co bCompany, @msg varchar(80) = '' output)
   
    as
    set nocount on
   
        declare @xrefname varchar(30), @datatype varchar(30), @pmtemplate varchar(10),
                @importedval varchar(30), @bidtekval varchar(30), @sourceident int,
                @phasegroup bGroup, @materialgroup bGroup, @vendorgroup bGroup,
                @phaseid int, @materialid int, @vendorid int, @defaultmaterial varchar(30),
                @defaultphase varchar(30), @defaultvendor varchar(30),
                @defaultjcco varchar(30), @APCo bCompany,
                @uploadgroup varchar(30), @importgroup varchar(30), @JCCo bCompany,
                @uploadco varchar(30), @importco varchar(30), @jccoid int,
                @targetident int, @recseq int, @xrefdval varchar(100),@rcode int
   
        select @rcode = 0
   
        if @importtemplate is null
        begin
            select @msg = 'Missing Import Template', @rcode = 1
            goto bspexit
        end
   
        if @importid is null
        begin
            select @msg = 'Missing ImportId', @rcode = 1
            goto bspexit
        end
   
        -- Check ImportTemplate detail for columns to set Cross Reference
        select @xrefname=IMTD.XRefName
        From IMTD
        join IMXH
        on IMTD.ImportTemplate=IMXH.ImportTemplate and IMTD.XRefName = IMXH.XRefName
        Where IMTD.ImportTemplate=@importtemplate AND isnull(IMTD.XRefName,'') <> ''
        and IMXH.PMCrossReference = 'Y'
        if @@rowcount = 0 goto bspexit
   
        select @jccoid = Identifier, @defaultjcco = DefaultValue
        from IMTD
        where ImportTemplate = @importtemplate  and
              Datatype = 'bJCCo'
   
        select @phaseid = Identifier, @defaultphase = DefaultValue
        from IMTD
        where ImportTemplate = @importtemplate  and
              ColDesc = 'Phase Group'
   
        select @materialid = Identifier, @defaultmaterial = DefaultValue
        from IMTD
        where ImportTemplate = @importtemplate  and
              ColDesc = 'Material Group'
   
        select @vendorid = Identifier, @defaultvendor = DefaultValue
        from IMTD
        where ImportTemplate = @importtemplate  and
              ColDesc = 'Vendor Group'
   
        declare cXRefHead cursor local fast_forward for
        select IMTD.XRefName, IMTD.Datatype, IMXH.PMTemplate
        From IMTD
        join IMXH
        on IMTD.ImportTemplate=IMXH.ImportTemplate and IMTD.XRefName = IMXH.XRefName
        Where IMTD.ImportTemplate=@importtemplate AND isnull(IMTD.XRefName,'') <> ''
        and IMXH.PMCrossReference = 'Y'
   
        open cXRefHead
   
        fetch next from cXRefHead into @xrefname, @datatype, @pmtemplate
   
        while @@fetch_status = 0
        begin
   
            --This is the target identifier where XRef'd value will be written to.
            select @targetident = Identifier
            from IMTD
            where ImportTemplate = @importtemplate and XRefName = @xrefname
   
            select @recseq = 0, @xrefdval = null
   
            while @recseq is not null
            begin
   
                declare cXRefCur cursor local fast_forward for
                    select ImportField
                    from IMXF
                    where ImportTemplate = @importtemplate
                        and XRefName = @xrefname
   
                open cXRefCur
   
                fetch next from cXRefCur into @sourceident
   
                while @@fetch_status = 0
                	begin
   
   				if @xrefdval is null
   					begin
   		                select @xrefdval = (select ltrim(ImportedVal) from IMWE
   		                     where ImportId = @importid and
           	                 ImportTemplate = @importtemplate and
               	             Identifier = @sourceident and RecordSeq = @recseq)
   					end
   				else
   					begin
    	 		            select @xrefdval = @xrefdval + (select ltrim(ImportedVal)
   	                    from IMWE where ImportId = @importid and ImportTemplate = @importtemplate and
                            Identifier = @sourceident and RecordSeq = @recseq)
   					end
   				--end mark 4/23
   
                    fetch next from cXRefCur into @sourceident
   
                end
   
                if isnull(@xrefdval,'') <> ''
                    begin
   					if @datatype = 'bPhase' and @datatype = 'bJCCType'
                          begin
   
    	 		            select @uploadgroup = UploadVal, @importgroup = ImportedVal
   	                    from IMWE where ImportId = @importid and ImportTemplate = @importtemplate and
                           Identifier = @phaseid and RecordSeq = @recseq
   
    	 		            select @uploadco = UploadVal, @importco = ImportedVal
   	                    from IMWE where ImportId = @importid and ImportTemplate = @importtemplate and
                           Identifier = @jccoid and RecordSeq = @recseq
   
                          If isnull(@defaultjcco,'')<>'' and isnull(@defaultjcco,'') <> '[Bidtek]' select @JCCo = @defaultjcco 
                          If isnull(@defaultjcco,'')='[Bidtek]' select @JCCo = @co
                          If isnull(@importco,'') <> '' select @JCCo = @co
                        
                          If isnull(@JCCo,'')='' select @JCCo = @co
   
                          If isnull(@defaultphase,'')<>'' and isnull(@defaultphase,'') <> '[Bidtek]' select @phasegroup = @defaultphase
                          If isnull(@defaultphase,'')='[Bidtek]' select @phasegroup = PhaseGroup from bHQCO where HQCo = @JCCo
                          If isnull(@importgroup,'')<>'' select @phasegroup = @importgroup
                         end
   
   
   					if @datatype = 'bPhase' -- Xreftype = 0 in PMUX Phase Group
                          begin
   
   					   If (Select Phase from PMUX where Template = @pmtemplate and
                              XrefCode = @xrefdval and PhaseGroup = @phasegroup and XrefType = 0) is not null
   						    begin
   		                    update IMWE set UploadVal = (Select Phase from PMUX 
                                                            where Template = @pmtemplate and PhaseGroup = @phasegroup and
                                                            XrefCode = @xrefdval and XrefType = 0)
                        		where ImportTemplate = @importtemplate and
                            		ImportId = @importid and Identifier = @targetident and RecordSeq = @recseq
   
   						    end
                           end
   
   					if @datatype = 'bJCCType' -- Xreftype = 1 in PMUX Phase Group
                          begin
   					   if (Select CostType from PMUX where Template = @pmtemplate and
                           XrefCode = @xrefdval and PhaseGroup = @phasegroup and XrefType = 1) is not null
   						    begin
   		                    update IMWE set UploadVal = (Select CostType from PMUX 
                                                            where Template = @pmtemplate and
                                                            XrefCode = @xrefdval and PhaseGroup = @phasegroup 
                                                            and XrefType = 1)
                        		where ImportTemplate = @importtemplate and
                            		ImportId = @importid and Identifier = @targetident and RecordSeq = @recseq
   
   						    end
                           end
   
   					if @datatype = 'bUM' -- Xreftype = 2 in PMUX No Group
                          begin
   					   if (Select TOP 1 UM from PMUX where Template = @pmtemplate and
                           XrefCode = @xrefdval and XrefType = 2) is not null
   						    begin
   		                    update IMWE set UploadVal = (Select UM from PMUX 
                                                            where Template = @pmtemplate and
                                                            XrefCode = @xrefdval and XrefType = 2)
                        		where ImportTemplate = @importtemplate and
                            		ImportId = @importid and Identifier = @targetident and RecordSeq = @recseq
   
   						    end
                           end
   
   					if @datatype = 'bMatl' -- Xreftype = 3 in PMUX Material Group
                          begin
   					   if (Select TOP 1 Material from PMUX where Template = @pmtemplate and
                           XrefCode = @xrefdval and XrefType = 3) is not null
   						    begin
   		                    update IMWE set UploadVal = (Select Material from PMUX 
                                                            where Template = @pmtemplate and
                                                            XrefCode = @xrefdval and XrefType = 3)
                        		where ImportTemplate = @importtemplate and
                            		ImportId = @importid and Identifier = @targetident and RecordSeq = @recseq
   
   						    end
                           end
   
   					if @datatype = 'bVendor' -- Xreftype = 4 in PMUX Vendor Group
                          begin
   					   if (Select TOP 1 Vendor from PMUX where Template = @pmtemplate and
                           XrefCode = @xrefdval and XrefType = 4) is not null
   						    begin
   		                    update IMWE set UploadVal = (Select Vendor from PMUX 
                                                            where Template = @pmtemplate and
                                                            XrefCode = @xrefdval and XrefType = 4)
                        		where ImportTemplate = @importtemplate and
                            		ImportId = @importid and Identifier = @targetident and RecordSeq = @recseq
   
   						    end
                           end
   
                    end
   
                close cXRefCur
                deallocate cXRefCur
                select @xrefdval = null
   
   
                select @recseq = min(RecordSeq)
                from IMWE
                where ImportTemplate = @importtemplate and
                    ImportId = @importid and
                    Identifier = @targetident and RecordSeq > @recseq
   
            end
   
            fetch next from cXRefHead into @xrefname
   
        end
   
        close cXRefHead
        deallocate cXRefHead
   
    bspexit:
   
         return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMCrossRefPMTemplate] TO [public]
GO
