using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web.Http;
using System.Web;
using McKinstry.Data.Models.Viewpoint;

namespace McKinstry.API.Controllers.Vista
{
    /// <summary>
    /// Viewpoint (Vista) Contract Items
    /// </summary>
    //[Authorize]
    [RoutePrefix("api/v1")]
    public class ContractItemsController : ApiController
    {
        ContractItem[] contractitems;
        /// <summary>
        /// Retreive All ContractItems for a given {ContractId} (include any leading spaces)
        /// </summary>
        /// <param name="ContractId"></param>
        /// <returns></returns>
        [Route("contractitems/{ContractId}")]
        public List<ContractItem> GetContractItemsByContract(string ContractId)
        {
            List<ContractItem> _retObj = new List<ContractItem>();

            //try
            //{ 
            //    impersonationContext = ((WindowsIdentity)User.Identity).Impersonate();

            string _conn_string = ConfigurationManager.ConnectionStrings["ViewpointConnection"].ToString();

            string _sql = String.Format("select JCCo, Contract, Item, Description from JCCI where JCCo in (1,20) and Contract='{0}' order by JCCo, Contract, Item", ContractId);
            SqlConnection _conn = new SqlConnection(_conn_string);

            _conn.Open();

            SqlCommand _cmd = new SqlCommand(_sql, _conn);
            SqlDataReader _reader = _cmd.ExecuteReader();


            while (_reader.Read())
            {
                ContractItem _contractitem = new ContractItem();
                _contractitem.CompanyId = System.Int16.Parse(_reader.GetValue(0).ToString());
                _contractitem.ContractId = _reader.GetValue(1).ToString();
                _contractitem.ContractItemId = _reader.GetValue(2).ToString();
                _contractitem.ContractItemName = _reader.GetValue(3).ToString();

                _retObj.Add(_contractitem);
            }

            _conn.Close();

            contractitems = _retObj.Cast<ContractItem>().ToArray();

            //contracts = _retObj.Cast<Contract>().ToArray();
            //}
            //finally
            //{
            //    if (impersonationContext != null)
            //    {
            //        impersonationContext.Undo();
            //    }
            //}

            return _retObj;
        }

    }
}