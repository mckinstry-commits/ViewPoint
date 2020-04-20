using System;
using System.Configuration;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web.Http;
using System.Web;

using McKinstry.Data.Models.Viewpoint;

namespace McKinstry.API.Controllers
{
    /// <summary>
    /// Viewpoint (Vista) Companies
    /// </summary>
    //[Authorize]
    [RoutePrefix("api/v1")]

    public class CompaniesController : ApiController
    {
        //Company[] companies;
        Companies companies;

        /// <summary>
        /// Returns a strong typed list of accessible Companies.
        /// </summary>
        /// <returns></returns>
        //[OperationBehavior(Impersonation = ImpersonationOption.Required)]
        [Route("companies")]
        [Route("companies/all")]
        //[Route("companies/all")]
        public Companies GetAllCompanies()
        {

            //WindowsImpersonationContext impersonationContext = null;

            Companies _retObj = new Companies();

            //try
            //{ 
            //    impersonationContext = ((WindowsIdentity)User.Identity).Impersonate();

            string _conn_string = ConfigurationManager.ConnectionStrings["ViewpointConnection"].ToString();

            //System.Collections.Specialized.NameValueCollection queries = (System.Collections.Specialized.NameValueCollection)ConfigurationManager.GetSection("queries");

            //string _sql = queries["CompanyList"].ToString();

            string _sql = "select HQCo, Name, suser_sname() as CurUser, '{0}' as WinUser from HQCO where udTESTCo <> 'Y' order by HQCo";

            SqlConnection _conn = new SqlConnection(_conn_string);

            _conn.Open();

            SqlCommand _cmd = new SqlCommand(_sql, _conn);
            SqlDataReader _reader = _cmd.ExecuteReader();


            while (_reader.Read())
            {
                Company _company = new Company();
                _company.CompanyId = System.Int16.Parse(_reader.GetValue(0).ToString());
                _company.CompanyName = _reader.GetValue(1).ToString();

                _retObj.Add(_company);

            }

            _conn.Close();

            companies = _retObj;
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
        /// Gets a single Company given a valid CompanyId
        /// </summary>
        [Route("company/{CompanyId}")]
        public IHttpActionResult GetCompany(int CompanyId)
        {
            companies = GetAllCompanies();
            var company = companies.FirstOrDefault((p) => p.CompanyId == CompanyId);
            if (company == null)
            {
                return NotFound();
            }
            return Ok(company);
        }
    }

}