SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bsp_helpselect    Script Date: 8/28/99 9:33:44 AM ******/
 CREATE    procedure [dbo].[bsp_helpselect]  -- 1995/09/13 18:23 --	danf 1/24/05 - issue #119669 (SQL 9.0 2005)
     @objname varchar(92) = NULL      /* object name we're after */
 as
 
 declare @objid int         /* id of the object */
 declare @sysstat smallint     /* the type of the object */
 declare @dbname varchar(30)
 declare @colname varchar(30)
 
 set nocount on
 
 /*
 **  Make sure the @objname is local to the current database.
 */
 if @objname like '%.%.%' and
    substring(@objname, 1, charindex('.', @objname) - 1) <> db_name()
    begin
       raiserror(15250,-1,-1)
       return(1)
    end
 
 /*
 **  Now check to see if the @objname is in sysobjects.  It has to be either
 **  in sysobjects or systypes.
 */
 select @objid = id, @sysstat = sysstat from sysobjects
    where id = object_id(@objname)
 
 /*
 **  If the object is a table, check out the indexes.
 */
  if @sysstat & 0xf in (1, 3)   -- system table or user table
    begin
       -- print ''
       set nocount on
       execute sp_helpindex2 @objname
    end
 
 /*
 **  If the object is a system table, view, or user table, we want to check
 **  out the object's columns here.
 */
 
 if @sysstat & 0xf in (1, 2, 3)   -- system table, view, or user table.
 begin
 
    create table #sphelptab
    (
       col_name char (30)   NULL,
       col_type char (30)   NULL,
       col_len     tinyint     NULL,
       col_prec char (5) NULL,
       col_scale   char (5) NULL,
       col_status  tinyint     NULL,
       colid    tinyint     NULL,
       type_systemdata  tinyint  NULL
    )
 
    insert into #sphelptab
       select c.name, t.name, c.length, convert(char(5),c.prec),
          convert(char(5),c.scale), c.status,
          c.colid, t.type
       from syscolumns c
	   left join systypes t
       on c.usertype = t.usertype
       where c.id = @objid
 
    /*
    ** Don't display precision and scale for datatypes
    ** for which they not applicable.
    */
    update #sphelptab
       set col_prec = '', col_scale = ''
       where col_type in
          (select name from systypes where type not in
          (38,48,52,55,56,59,60,62,63,106,108,109,110,122))
 
    print ''
    select rtrim(col_name) + ','
 
    from #sphelptab
    order by colid
 
    -- See if there is an identity column.
 
    -- print ''
    select @colname = null
    select @colname = col_name from #sphelptab
       where (col_status & 128) = 128
 
 end
 
 return (0)


GO
GRANT EXECUTE ON  [dbo].[bsp_helpselect] TO [public]
GO
