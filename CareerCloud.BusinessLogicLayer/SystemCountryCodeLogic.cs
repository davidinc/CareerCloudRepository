using CareerCloud.DataAccessLayer;
using CareerCloud.Pocos;

namespace CareerCloud.BusinessLogicLayer
{
    public class SystemCountryCodeLogic
    {
        protected IDataRepository<SystemCountryCodePoco> _repository;

        public SystemCountryCodeLogic(IDataRepository<SystemCountryCodePoco> repository)
        {
            _repository= repository;
        }

        protected virtual void Verify(SystemCountryCodePoco[] pocos)
        {
            foreach (var poco in pocos)
            {

                List<ValidationException> errors = new List<ValidationException>();
                // Defining Exceptional validation for ErrorCode 901/900

                if (string.IsNullOrEmpty(poco.Name))
                {
                    errors.Add(new ValidationException(901, "Cannot be empty"));
                }

                if (string.IsNullOrEmpty(poco.Code))
                {
                    errors.Add(new ValidationException(900, "Cannot be empty"));
                }


                if (errors.Count > 0)
                {
                    throw new AggregateException(errors);
                }
            }
        }

        public SystemCountryCodePoco GetByCode(string code)
        {
            return _repository.GetSingle(c => c.Code == code);
        }

        public  List<SystemCountryCodePoco> GetAll()
        {
            return _repository.GetAll().ToList();
        }

        public SystemCountryCodePoco Get(string Code)
        {
            return _repository.GetSingle(c => c.Code == Code);
        }


        public  void Add(SystemCountryCodePoco[] pocos)
        {
            Verify(pocos);

            _repository.Add(pocos);
        }

        public  void Update(SystemCountryCodePoco[] pocos)
        {
            Verify(pocos);
            _repository.Update(pocos);
        }

        public void Delete(SystemCountryCodePoco[] pocos)
        {
            _repository.Remove(pocos);
        }

    }
}
