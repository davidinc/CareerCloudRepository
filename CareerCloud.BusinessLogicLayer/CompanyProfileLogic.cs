using System.Text.RegularExpressions;
using CareerCloud.DataAccessLayer;
using CareerCloud.Pocos;

namespace CareerCloud.BusinessLogicLayer
{
    public class CompanyProfileLogic : BaseLogic<CompanyProfilePoco>
    {
        public CompanyProfileLogic(IDataRepository<CompanyProfilePoco> repository) : base(repository) 
        { }

        protected override void Verify(CompanyProfilePoco[] pocos)
        {

            foreach (var poco in pocos)
            {

                List<ValidationException> errors = new List<ValidationException>();

                // Defining Exceptional validation for ErrorCode 600/601
                if (poco.CompanyWebsite!=null && !(poco.CompanyWebsite.EndsWith(".ca") || poco.CompanyWebsite.EndsWith(".com") || poco.CompanyWebsite.EndsWith(".biz")))
                {
                    errors.Add(new ValidationException(600, "must end with the following extensions – \".ca\", \".com\", \".biz\""));
                }
                
                if((string.IsNullOrEmpty(poco.ContactPhone) || !(Regex.IsMatch (poco.ContactPhone, @"^\d{3}-\d{3}-\d{4}$"))))
                {
                    errors.Add(new ValidationException(601, "Must correspond to a valid phone number (e.g. 416-555-1234)"));
                }

                if (errors.Count > 0)
                {
                    throw new AggregateException(errors);
                }
            }

        }

        public override void Add(CompanyProfilePoco[] pocos)
        {
            Verify(pocos);
            base.Add(pocos);
        }

        public override void Update(CompanyProfilePoco[] pocos)
        {
            Verify(pocos);
            base.Update(pocos);
        }
    }
}
