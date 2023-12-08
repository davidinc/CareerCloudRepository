using CareerCloud.DataAccessLayer;
using CareerCloud.Pocos;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CareerCloud.BusinessLogicLayer
{
    public class ApplicantJobApplicationLogic : BaseLogic<ApplicantJobApplicationPoco>
    {
        public ApplicantJobApplicationLogic(IDataRepository<ApplicantJobApplicationPoco> repository) : base(repository)
        { }

        protected override void Verify(ApplicantJobApplicationPoco[] pocos)
        {

            foreach (var poco in pocos)
            {
                List<ValidationException> errors = new List<ValidationException>();
                // Defining Exceptional validation for ErrorCode 110

                if (poco.ApplicationDate > DateTime.Today)
                {
                    errors.Add(new ValidationException(110, "ApplicationDate cannot be greater than today"));
                }

                if (errors.Count > 0)
                {
                    throw new AggregateException(errors);
                }
            }

        }

        public override void Add(ApplicantJobApplicationPoco[] pocos)
        {
            Verify(pocos);
            base.Add(pocos);
        }

        public override void Update(ApplicantJobApplicationPoco[] pocos)
        {
            Verify(pocos);
            base.Update(pocos);
        }

    }
}
