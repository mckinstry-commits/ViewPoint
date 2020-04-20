SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspVPPermissionCheck]
    /*****************************************
     * Created: GG 09/08/99
     * Modified: DANF 11/27/01 Added onwer restriction to 'dbo'
     *
     * Usage:
     * Lists Views without SELECT, INSERT, DELETE, or UPDATE permissions
     * Lists Procedures without EXECUTE permission
     *
     *
     *************************************/
    as
   
    select DB_NAME()
   
     -- Views missing select, insert, delete, or update permission
    select o.name as 'Views w/o SELECT permission'
    from sysobjects o
    left join sysprotects p on o.id=p.id
     where (p.action <> 193 and p.action not in (195,196,197) or p.action is null) and o.type = 'V' and user_name(o.uid)='dbo'
    order by o.name
   
    select o.name as 'Views w/o INSERT permission'
    from sysobjects o
    left join sysprotects p on o.id=p.id
     where (p.action <> 195 and p.action not in (193,196,197) or p.action is null) and o.type = 'V'and user_name(o.uid)='dbo'
    order by o.name
   
    select o.name as 'Views w/o DELETE permission'
    from sysobjects o
    left join sysprotects p on o.id=p.id
     where (p.action <> 196 and p.action not in (193,195,197) or p.action is null) and o.type = 'V' and user_name(o.uid)='dbo'
    order by o.name
   
    select o.name as 'Views w/o UPDATE permission'
    from sysobjects o
    left join sysprotects p on o.id=p.id
     where (p.action <> 197 and p.action not in (193,195,196) or p.action is null) and o.type = 'V' and user_name(o.uid)='dbo'
    order by o.name
   
    -- Procedures missing execute permission
    select o.name as 'Procedures w/o EXEC permission'
    from sysobjects o
    left join sysprotects p on o.id=p.id
     where (p.action <> 224 or p.action is null) and o.type = 'P' and user_name(o.uid)='dbo'
    order by o.name
   
    return

GO
GRANT EXECUTE ON  [dbo].[bspVPPermissionCheck] TO [public]
GO
