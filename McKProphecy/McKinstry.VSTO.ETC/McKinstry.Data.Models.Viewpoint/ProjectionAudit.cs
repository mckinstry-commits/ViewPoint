

namespace McKinstry.Data.Models.Viewpoint
{
    public class ProjectionAudit
    {
        public ProjectionAudit(string contract, object job, object lastSave, object saveUser, object lastPost, object postUser) 
        {
            Contract = contract;
            Job = job;
            LastSave = lastSave;
            SaveUser = saveUser;
            LastPost = lastPost;
            PostUser = postUser;
        }

        public string Contract { get; set; }

        public object Job { get; set; }

        public object LastSave { get; set; }

        public object SaveUser { get; set; }

        public object LastPost { get; set; }

        public object PostUser { get; set; }
    }
}
