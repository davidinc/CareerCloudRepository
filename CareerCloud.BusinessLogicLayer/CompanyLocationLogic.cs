using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using CareerCloud.DataAccessLayer;
using CareerCloud.Pocos;

namespace CareerCloud.BusinessLogicLayer
{
    public class CompanyLocationLogic : BaseLogic<CompanyLocationPoco>
    {
        public CompanyLocationLogic(IDataRepository<CompanyLocationPoco> repository) : base(repository) 
        { }

        protected override void Verify(CompanyLocationPoco[] pocos)
        {

            foreach (var poco in pocos)
            {

                List<ValidationException> errors = new List<ValidationException>();
                // Defining Exceptional validation for ErrorCode 500/501/502/503/504

                if (string.IsNullOrEmpty(poco.CountryCode))
                {
                    errors.Add(new ValidationException(500, "CountryCode cannot be empty"));

                }

                if (string.IsNullOrEmpty(poco.Province))
                {
                    errors.Add(new ValidationException(501, "Province cannot be empty"));

                }

                if (string.IsNullOrEmpty(poco.Street))
                {
                    errors.Add(new ValidationException(502, "Street cannot be empty"));

                }

                if (string.IsNullOrEmpty(poco.City))
                {
                    errors.Add(new ValidationException(503, "City cannot be empty"));

                }
                if (string.IsNullOrEmpty(poco.PostalCode))
                {
                    errors.Add(new ValidationException(504, "PostalCode cannot be empty"));

                }



                if (errors.Count > 0)
                {
                    throw new AggregateException(errors);
                }
            }

        }

        public override void Add(CompanyLocationPoco[] pocos)
        {
            Verify(pocos);
            base.Add(pocos);
        }

        public override void Update(CompanyLocationPoco[] pocos)
        {
            Verify(pocos);
            base.Update(pocos);
        }
    }
}
