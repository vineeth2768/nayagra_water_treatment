import '../models/customer_model.dart';
import '../repositories/customer_repository.dart';
import '../repositories/service_repository.dart';

class CustomerController {
  final CustomerRepository _customerRepository;
  final ServiceRepository _serviceRepository;

  CustomerController({
    required CustomerRepository customerRepository,
    required ServiceRepository serviceRepository,
  })  : _customerRepository = customerRepository,
        _serviceRepository = serviceRepository;

  Stream<List<CustomerModel>> getCustomersStream() {
    return _customerRepository.getCustomersStream();
  }

  Future<List<CustomerModel>> getAllCustomers() async {
    return await _customerRepository.getCustomers();
  }

  Future<CustomerModel?> getCustomer(String id) async {
    return await _customerRepository.getCustomerById(id);
  }

  /// Creates customer and triggers automatic 1st service generation (+6 months)
  Future<String> createCustomer(CustomerModel customer) async {
    final customerId = await _customerRepository.addCustomer(customer);
    final savedCustomer = customer.copyWith(id: customerId);
    await _serviceRepository.scheduleFirstService(savedCustomer);
    return customerId;
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    await _customerRepository.updateCustomer(customer);
  }

  Future<void> deleteCustomer(String id) async {
    await _customerRepository.deleteCustomer(id);
  }
}
