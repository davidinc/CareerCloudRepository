using CareerCloud.DataAccessLayer;

namespace CareerCloud.EntityFrameworkDataAccess
{
    public class EFGenericRepository<T> : IDataRepository<T> where T : class

    {
        // DbSet<T> set;

        public const string cs = "Server =(LocalDB)\\MSSQLLocalDB;Database=JOB_PORTAL_DB;Integrated Security=True;MultipleActiveResultSets=true;Encrypt=False";

        public void Add(params T[] items)
        {

            using (CareerCloudContext context = new CareerCloudContext(cs))
            {
                foreach (var item in items)
                {
                    context.Add(item);

                }
                context.SaveChanges();


                // throw new NotImplementedException();
            }
        }

        public void CallStoredProc(string name, params Tuple<string, string>[] parameters)
        {
            throw new NotImplementedException();
        }

        public IList<T> GetAll(params System.Linq.Expressions.Expression<Func<T, object>>[] navigationProperties)
        {
            List<T> list = new List<T>();

            using (CareerCloudContext context = new CareerCloudContext(cs))
            {

                foreach (var item in context.Set<T>())
                {
                    list.Add(item);

                }
                return list;

            }
        }
        public IList<T> GetList(System.Linq.Expressions.Expression<Func<T, bool>> where, params System.Linq.Expressions.Expression<Func<T, object>>[] navigationProperties)
        {
            throw new NotImplementedException();
        }

        public T GetSingle(System.Linq.Expressions.Expression<Func<T, bool>> where, params System.Linq.Expressions.Expression<Func<T, object>>[] navigationProperties)
        {
            IQueryable<T> pocos = GetAll().AsQueryable();

            return pocos.Where(where).FirstOrDefault();
        }

        public void Remove(params T[] items)
        {

            using (CareerCloudContext context = new CareerCloudContext(cs))
            {

                foreach (var item in items)
                {
                    context.Remove(item);

                }
                context.SaveChanges();

            }
        }

        public void Update(params T[] items)
        {
            using (CareerCloudContext context = new CareerCloudContext(cs))
            {

                foreach (var item in items)
                {
                    context.Update(item);

                }
                context.SaveChanges();


                // throw new NotImplementedException();
            }
        }
    }
}
