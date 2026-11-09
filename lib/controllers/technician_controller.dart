import '../models/technician_model.dart';
import '../repositories/technician_repository.dart';

class TechnicianController {
  final TechnicianRepository _repository;

  TechnicianController({required TechnicianRepository repository})
      : _repository = repository;

  Stream<List<TechnicianModel>> getTechniciansStream() {
    return _repository.getTechniciansStream();
  }

  Future<List<TechnicianModel>> getAllTechnicians() async {
    return await _repository.getTechnicians();
  }

  Future<String> addTechnician(TechnicianModel technician) async {
    return await _repository.addTechnician(technician);
  }

  Future<void> updateTechnician(TechnicianModel technician) async {
    await _repository.updateTechnician(technician);
  }

  Future<void> deleteTechnician(String id) async {
    await _repository.deleteTechnician(id);
  }
}

