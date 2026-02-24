import 'package:flutter/material.dart';
import '../../app_colors.dart';

class AIVerificationScreen extends StatefulWidget {
  const AIVerificationScreen({super.key});

  @override
  State<AIVerificationScreen> createState() => _AIVerificationScreenState();
}

class _AIVerificationScreenState extends State<AIVerificationScreen> {
  bool _hasResult = false;
  bool _isAnalyzing = false;
  bool _hasImage = false;
  String _imageSource = 'No image selected';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Insect Inspection'),
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI-Powered Detection',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(
              'Use AI to verify insect health and identify species',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 24),

            // Camera/Upload Area
            if (!_hasResult) ...[
              _CameraViewfinder(
                isAnalyzing: _isAnalyzing,
                hasImage: _hasImage,
                label: _imageSource,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isAnalyzing ? null : _simulateCapture,
                      icon: Icon(Icons.camera_alt_outlined),
                      label: Text('Capture'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isAnalyzing ? null : _simulateUpload,
                      icon: Icon(Icons.image_outlined),
                      label: Text('Upload'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _runAnalysis,
                  icon: Icon(Icons.auto_awesome),
                  label: Text('Run AI Analysis'),
                ),
              ),
            ] else
              _buildResultCard(context),

            if (_hasResult) ...[
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _hasResult = false);
                  },
                  child: Text('Analyze Another Image'),
                ),
              ),
            ],

            SizedBox(height: 24),

            // Information Cards
            Text(
              'How It Works',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 12),

            _InfoCard(
              number: '1',
              title: 'Capture Image',
              description: 'Take a clear photo of the insect specimen',
            ),
            SizedBox(height: 12),

            _InfoCard(
              number: '2',
              title: 'AI Analysis',
              description: 'Our AI model identifies species and health status',
            ),
            SizedBox(height: 12),

            _InfoCard(
              number: '3',
              title: 'Get Results',
              description: 'View detailed detection results and recommendations',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.image_outlined, size: 40, color: AppColors.textHint),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'HEALTHY',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Mealworm Beetle',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Divider(height: 1),
            SizedBox(height: 16),
            _ResultRow(label: 'Species', value: 'Tenebrio molitor'),
            SizedBox(height: 12),
            _ResultRow(label: 'Confidence', value: '94.2%'),
            SizedBox(height: 12),
            _ResultRow(label: 'Health Status', value: 'Excellent'),
            SizedBox(height: 12),
            _ResultRow(label: 'Age Estimate', value: '6-8 weeks'),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'This specimen appears to be in optimal condition. No health concerns detected.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _simulateAnalysis() {
    setState(() => _isAnalyzing = true);
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isAnalyzing = false;
        _hasResult = true;
      });
    });
  }

  void _simulateCapture() {
    setState(() {
      _hasImage = true;
      _imageSource = 'Captured from camera';
    });
  }

  void _simulateUpload() {
    setState(() {
      _hasImage = true;
      _imageSource = 'Uploaded from gallery';
    });
  }

  void _runAnalysis() {
    if (!_hasImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please capture or upload an image first.')),
      );
      return;
    }
    _simulateAnalysis();
  }
}

class _CameraViewfinder extends StatelessWidget {
  final bool isAnalyzing;
  final bool hasImage;
  final String label;

  const _CameraViewfinder({
    required this.isAnalyzing,
    required this.hasImage,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live View', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.shade200,
                          Colors.grey.shade100,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ViewfinderPainter(),
                    ),
                  ),
                  if (!hasImage)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 48, color: AppColors.textHint),
                          SizedBox(height: 8),
                          Text('Camera Preview', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    )
                  else
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  if (isAnalyzing)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(AppColors.primary),
                                strokeWidth: 3,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Analyzing...',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;

    // Grid lines
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), gridPaint);
    canvas.drawLine(Offset(2 * size.width / 3, 0), Offset(2 * size.width / 3, size.height), gridPaint);
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), gridPaint);
    canvas.drawLine(Offset(0, 2 * size.height / 3), Offset(size.width, 2 * size.height / 3), gridPaint);

    // Corner brackets
    final corner = 18.0;
    canvas.drawLine(Offset(12, 12), Offset(12 + corner, 12), paint);
    canvas.drawLine(Offset(12, 12), Offset(12, 12 + corner), paint);

    canvas.drawLine(Offset(size.width - 12, 12), Offset(size.width - 12 - corner, 12), paint);
    canvas.drawLine(Offset(size.width - 12, 12), Offset(size.width - 12, 12 + corner), paint);

    canvas.drawLine(Offset(12, size.height - 12), Offset(12 + corner, size.height - 12), paint);
    canvas.drawLine(Offset(12, size.height - 12), Offset(12, size.height - 12 - corner), paint);

    canvas.drawLine(Offset(size.width - 12, size.height - 12), Offset(size.width - 12 - corner, size.height - 12), paint);
    canvas.drawLine(Offset(size.width - 12, size.height - 12), Offset(size.width - 12, size.height - 12 - corner), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _InfoCard({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  number,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  SizedBox(height: 4),
                  Text(description, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
