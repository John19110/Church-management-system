public class UserAlreadyExistsException : Exception
{
    public UserAlreadyExistsException(string message = "Phone number already exists.") : base(message) { }
}