import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taxi_driver/src/core/providers/registration_provider.dart';
import 'package:taxi_driver/src/features/registration/screens/document_upload_screen.dart';

class VehicleInformationScreen extends StatefulWidget {
  const VehicleInformationScreen({super.key});

  @override
  State<VehicleInformationScreen> createState() => _VehicleInformationScreenState();
}

class _VehicleInformationScreenState extends State<VehicleInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _makeModelController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  
  String? _selectedVehicleType;
  String? _selectedVehicleColor;
  final ImagePicker _picker = ImagePicker();

  final List<String> _vehicleTypes = ['Sedan', 'SUV', 'Hatchback', 'Truck', 'Van'];
  final List<String> _vehicleColors = ['Black', 'White', 'Silver', 'Red', 'Blue', 'Gray', 'Other'];

  @override
  void dispose() {
    _makeModelController.dispose();
    _licensePlateController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _pickVehiclePhotos() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        if (!mounted) return;
        final provider = Provider.of<RegistrationProvider>(context, listen: false);
        for (var image in images) {
          provider.addVehiclePhoto(File(image.path));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  Future<void> _selectYear() async {
    final int currentYear = DateTime.now().year;
    final int? picked = await showDialog<int>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select Year'),
          children: List.generate(15, (index) {
            final year = currentYear - index;
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, year),
              child: Text(year.toString()),
            );
          }),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _yearController.text = picked.toString();
      });
    }
  }

  void _continueToNext() {
    if (_formKey.currentState!.validate()) {
      if (_selectedVehicleType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select vehicle type')),
        );
        return;
      }
      if (_selectedVehicleColor == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select vehicle color')),
        );
        return;
      }

      final registrationProvider = Provider.of<RegistrationProvider>(context, listen: false);
      
      registrationProvider.saveVehicleInfo({
        'type': _selectedVehicleType,
        'make': _makeModelController.text.split(' ').first,
        'model': _makeModelController.text.split(' ').skip(1).join(' '),
        'licensePlate': _licensePlateController.text,
        'year': int.tryParse(_yearController.text) ?? DateTime.now().year,
        'color': _selectedVehicleColor,
      });

      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const DocumentUploadScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Step 2 of 4',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
                Text(
                  '50%',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 8,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                child: LinearProgressIndicator(
                  value: 0.5,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 12 / 255),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.yellow.withValues(alpha: 12 / 255),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 50 / 255),
                            width: 8,
                          ),
                        ),
                        child: const Icon(
                          Icons.directions_car_filled_outlined,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Vehicle Information',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tell us about the vehicle you\'ll be driving',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text('Vehicle Type *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedVehicleType,
                      items: _vehicleTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedVehicleType = value;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Select vehicle type',
                        prefixIcon: Icon(Icons.directions_car_outlined, size: 20),
                        filled: true,
                        fillColor: Color(0xFFF3F3F3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12.0)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(height: 20),
                    const Text('Make & Model *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _makeModelController,
                      validator: (value) => value?.isEmpty ?? true ? 'Please enter make and model' : null,
                      decoration: const InputDecoration(
                        hintText: 'e.g., Toyota Camry, Honda Civic',
                        prefixIcon: Icon(Icons.info_outline, size: 20),
                        filled: true,
                        fillColor: Color(0xFFF3F3F3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12.0)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('License Plate Number *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _licensePlateController,
                      validator: (value) => value?.isEmpty ?? true ? 'Please enter license plate' : null,
                      decoration: const InputDecoration(
                        hintText: 'ABC-1234',
                        prefixIcon: Icon(Icons.pin_outlined, size: 20),
                        filled: true,
                        fillColor: Color(0xFFF3F3F3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12.0)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Year of Manufacture *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _yearController,
                      readOnly: true,
                      onTap: _selectYear,
                      validator: (value) => value?.isEmpty ?? true ? 'Please select year' : null,
                      decoration: const InputDecoration(
                        hintText: 'Select year',
                        prefixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                        suffixIcon: Icon(Icons.arrow_drop_down, size: 24),
                        filled: true,
                        fillColor: Color(0xFFF3F3F3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12.0)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Vehicle must be 2010 or newer', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 20),
                    const Text('Vehicle Color *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedVehicleColor,
                      items: _vehicleColors.map((color) {
                        return DropdownMenuItem(
                          value: color,
                          child: Text(color, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedVehicleColor = value;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Select color',
                        prefixIcon: Icon(Icons.color_lens_outlined, size: 20),
                        filled: true,
                        fillColor: Color(0xFFF3F3F3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12.0)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(height: 30),
                    const Text('Vehicle Photos *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('Upload clear photos of your vehicle (front, back, and both sides)', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 16),
                    Consumer<RegistrationProvider>(
                      builder: (context, provider, child) {
                        return Column(
                          children: [
                            if (provider.vehiclePhotos.isNotEmpty)
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: provider.vehiclePhotos.length,
                                  itemBuilder: (context, index) {
                                    return Stack(
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(right: 8),
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            image: DecorationImage(
                                              image: FileImage(provider.vehiclePhotos[index]),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 12,
                                          child: GestureDetector(
                                            onTap: () => provider.removeVehiclePhoto(index),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: _pickVehiclePhotos,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 30),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid, width: 1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(children: [
                                  Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade200),
                                      child: const Icon(
                                        Icons.camera_alt_outlined,
                                        size: 30,
                                        color: Colors.black87,
                                      )),
                                  const SizedBox(height: 16),
                                  const Text('Upload Vehicle Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 8),
                                  Text('Tap to select photos or take new ones', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  const SizedBox(height: 20),
                                  OutlinedButton.icon(
                                      onPressed: _pickVehiclePhotos,
                                      icon: const Icon(Icons.add, color: Colors.black),
                                      label: const Text(
                                        'Add Photos',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: Colors.grey.shade400),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))
                                ]),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 25 / 255),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 20),
                              const SizedBox(width: 8),
                              Text('Vehicle Requirements', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(children: [const Icon(Icons.check, size: 16, color: Colors.green), const SizedBox(width: 8), Text('Vehicle must be 2010 or newer', style: TextStyle(color: Colors.grey.shade700))]),
                          const SizedBox(height: 8),
                          Row(children: [const Icon(Icons.check, size: 16, color: Colors.green), const SizedBox(width: 8), Text('4-door vehicles preferred', style: TextStyle(color: Colors.grey.shade700))]),
                          const SizedBox(height: 8),
                          Row(children: [const Icon(Icons.check, size: 16, color: Colors.green), const SizedBox(width: 8), Text('Clean interior and exterior', style: TextStyle(color: Colors.grey.shade700))]),
                          const SizedBox(height: 8),
                          Row(children: [const Icon(Icons.check, size: 16, color: Colors.green), const SizedBox(width: 8), Text('Valid registration and insurance', style: TextStyle(color: Colors.grey.shade700))]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _continueToNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continue to Next Step',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: Colors.white),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text.rich(
                      TextSpan(
                        text: 'By continuing, you agree to our ',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        children: const [
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                          ),
                          TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
