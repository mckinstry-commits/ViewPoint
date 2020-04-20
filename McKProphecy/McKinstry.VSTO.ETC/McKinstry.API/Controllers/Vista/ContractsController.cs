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
    /// Viewpoint (Vista) Contracts
    /// </summary>
    //[Authorize]
    [RoutePrefix("api/v1")]
    public class ContractsController : ApiController
    {
        Contract[] contracts;

        /// <summary>
        /// Get all Contracts of Status 1 or 2 in Companies 1 or 20
        /// </summary>
        /// <returns></returns>
        [Route("contracts")]
        [Route("contracts/all")]
        public Contracts GetAllContracts()
        {

            //WindowsImpersonationContext impersonationContext = null;

            Contracts _retObj = new Contracts();

            //try
            //{ 
            //    impersonationContext = ((WindowsIdentity)User.Identity).Impersonate();

            string _conn_string = ConfigurationManager.ConnectionStrings["ViewpointConnection"].ToString();

            string _sql = "select JCCo, Contract, Description from JCCM where JCCo in (1,20) and ContractStatus in (1,2) order by JCCo, Contract";
            SqlConnection _conn = new SqlConnection(_conn_string);

            _conn.Open();

            SqlCommand _cmd = new SqlCommand(_sql, _conn);
            SqlDataReader _reader = _cmd.ExecuteReader();


            while (_reader.Read())
            {
                Contract _contract = new Contract();
                _contract.CompanyId = System.Int16.Parse(_reader.GetValue(0).ToString());
                _contract.ContractId = _reader.GetValue(1).ToString();
                _contract.ContractName = _reader.GetValue(2).ToString();

                _retObj.Add(_contract);

            }

            _conn.Close();

            contracts = _retObj.Cast<Contract>().ToArray();
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

        /// <summary>
        /// Get all Contracts of Status 1 (Open) in Companies 1 or 20
        /// </summary>
        [Route("opencontracts")]
        [Route("contracts/open")]
        public List<Contract> GetOpenContracts()
        {

            //WindowsImpersonationContext impersonationContext = null;

            List<Contract> _retObj = new List<Contract>();

            //try
            //{ 
            //    impersonationContext = ((WindowsIdentity)User.Identity).Impersonate();

            string _conn_string = ConfigurationManager.ConnectionStrings["ViewpointConnection"].ToString();

            string _sql = "select JCCo, Contract, Description from JCCM where JCCo in (1,20) and ContractStatus = 1 order by JCCo, Contract";
            SqlConnection _conn = new SqlConnection(_conn_string);

            _conn.Open();

            SqlCommand _cmd = new SqlCommand(_sql, _conn);
            SqlDataReader _reader = _cmd.ExecuteReader();


            while (_reader.Read())
            {
                Contract _contract = new Contract();
                _contract.CompanyId = System.Int16.Parse(_reader.GetValue(0).ToString());
                _contract.ContractId = _reader.GetValue(1).ToString();
                _contract.ContractName = _reader.GetValue(2).ToString();

                _retObj.Add(_contract);

            }

            _conn.Close();

            contracts = _retObj.Cast<Contract>().ToArray();
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

        /// <summary>
        /// Get all Contracts of Status 1 or 2 in Companies 1 or 20 for a given {ContractId} (include any leading spaces)
        /// </summary>

        [Route("contract/{ContractId}")]
        public List<Contract> GetContract(string ContractId)
        {
            List<Contract> _retObj = new List<Contract>();

            //try
            //{ 
            //    impersonationContext = ((WindowsIdentity)User.Identity).Impersonate();

            string _conn_string = ConfigurationManager.ConnectionStrings["ViewpointConnection"].ToString();


            string _sql = String.Format("select JCCo, Contract, Description from JCCM where JCCo in (1,20) and ContractStatus in (1,2) and Contract='{0}' order by JCCo, Contract", ContractId);
            SqlConnection _conn = new SqlConnection(_conn_string);

            _conn.Open();

            SqlCommand _cmd = new SqlCommand(_sql, _conn);
            SqlDataReader _reader = _cmd.ExecuteReader();

            ContractItemsController _cic = new ContractItemsController();

            while (_reader.Read())
            {
                Contract _contract = new Contract();
                _contract.CompanyId = System.Int16.Parse(_reader.GetValue(0).ToString());
                _contract.ContractId = _reader.GetValue(1).ToString();
                _contract.ContractName = _reader.GetValue(2).ToString();

                _contract.Items = _cic.GetContractItemsByContract(ContractId);

                _retObj.Add(_contract);
            }

            _conn.Close();


            contracts = _retObj.Cast<Contract>().ToArray();

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

        /// <summary>
        /// Get all Contracts of Status 1 or 2 in Companies 1 or 20 for a given {ContractId} (include any leading spaces) as a SQL DataTable
        /// </summary>
        [Route("contracttable/{ContractId}")]
        public DataTable GetContractTable(string ContractId)
        {
            DataTable resultTable = new DataTable();

            string _conn_string = ConfigurationManager.ConnectionStrings["ViewpointConnection"].ToString();
            string _sql = String.Format("select JCCo, Contract, Description from JCCM where JCCo in (1,20) and ContractStatus in (1,2) and Contract='{0}' order by JCCo, Contract", ContractId);
            SqlConnection _conn = new SqlConnection(_conn_string);

            try { 
                _conn.Open();

                SqlCommand _cmd = new SqlCommand(_sql, _conn);
                SqlDataAdapter _da = new SqlDataAdapter(_cmd);

                _da.Fill(resultTable);
                resultTable.TableName = "Contract";
            }
            catch ( Exception e )
            {
                throw new Exception("GetContract Exception", e);
            }
            finally
            {
                if ( !(_conn.State == ConnectionState.Closed) )
                {
                    _conn.Close();
                }
                _conn = null;
            }

            return resultTable;
        }
    }
}