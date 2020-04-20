using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace McKinstry.API.Controllers
{
    //[Authorize]
    public class HomeController : Controller
    {
        public ActionResult Index()
        {
            return View("Index");
        }

        public ActionResult About()
        {
            ViewBag.Message = "McKinstry API";

            return View("About");
        }

        public ActionResult Contact()
        {
            ViewBag.Message = "For questions or inquiries, please contact:";

            return View("Contact");
        }
    }
}