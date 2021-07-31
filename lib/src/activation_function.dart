import 'dart:math' as math;

import 'dart:typed_data';

enum ActivationFunctionType { logistic, tanh, abs, bell, gelu, lelu }

double tanh(double x) {
  var e2x = math.exp(2 * x);
  return (e2x - 1) / (e2x + 1);
}

double tanhDeriv(double x) {
  var ex = math.exp(x);
  var sech = (2 * ex) / (ex * ex + 1);
  return sech * sech;
}

double sech(double x) {
  return 2.0 / (math.exp(x) + math.exp(-x));
}

double sinh(double x) {
  return (math.exp(x) - math.exp(-x)) / 2.0;
}

const SQRT_TWO_DIV_PI = 0.7978845608028653558798921198687;

class ActivationFunction {
  const ActivationFunction(this.type, this.lowerLimit, this.upperLimit,
      {required this.func,
      required this.derivative,
      this.funcSIMD,
      this.derivativeSIMD});
  final double Function(double) func;
  final double Function(double) derivative;
  final Float32x4 Function(Float32x4)? funcSIMD;
  final Float32x4 Function(Float32x4)? derivativeSIMD;
  final ActivationFunctionType type;
  final double upperLimit;
  final double lowerLimit;
}

double geluFunc(double x) {
  return 0.5 * x * (1 + tanh(SQRT_TWO_DIV_PI * (x + 0.044715 * x * x * x)));
}

double geluDeriv(double x) {
  double triple_x = x * x * x;
  double exp_x = SQRT_TWO_DIV_PI * x + 0.0356774 * triple_x;
  double exp_part = math.exp(exp_x);
  double exp_part_minus = math.exp(-exp_x);
  double sech_part = 2.0 / (exp_part + exp_part_minus);
  double tanh_part = 0.5 * (exp_part - exp_part_minus) * sech_part;
  return 0.5 +
      (0.398942 * x + 0.0535161 * triple_x) * sech_part * sech_part +
      0.5 * tanh_part;
}

const ActivationFunction activationGELU = ActivationFunction(
    ActivationFunctionType.gelu, -0.2, double.infinity,
    func: geluFunc, derivative: geluDeriv);

double bellFunc(double x) {
  return math.exp(-0.5 * x * x);
}

double bellDeriv(double x) {
  return -x * math.exp(-0.5 * x * x);
}

const ActivationFunction activationBell = ActivationFunction(
    ActivationFunctionType.bell, 0.0, 1.0,
    func: bellFunc, derivative: bellDeriv);

double absSigmoidFunc(double x) {
  return x / (1 + x.abs());
}

double absSigmoidDeriv(double x) {
  double abs_plus_one = 1 + x.abs();
  return 1 / (abs_plus_one * abs_plus_one);
}

final Float32x4 ones = Float32x4.splat(1);
Float32x4 absSigmoidFuncX4(Float32x4 x) {
  return x / (ones + x.abs());
}

Float32x4 absSigmoidDerivX4(Float32x4 x) {
  Float32x4 abs_plus_one = (ones + x.abs());
  return (abs_plus_one * abs_plus_one).reciprocal();
}

const ActivationFunction activationAbsSigmoid = ActivationFunction(
    ActivationFunctionType.abs, -1.0, 1.0,
    func: absSigmoidFunc,
    derivative: absSigmoidDeriv,
    funcSIMD: absSigmoidFuncX4,
    derivativeSIMD: absSigmoidDerivX4);

const ActivationFunction activationTanh = ActivationFunction(
    ActivationFunctionType.tanh, -1.0, 1.0,
    func: tanh, derivative: tanhDeriv);

double logisticFunc(double x) {
  return 2 / (1 + math.exp(-x)) - 1;
}

double logisticDeriv(double x) {
  var emx = math.exp(-x);
  return 2 * emx / ((1 + emx) * (1 + emx));
}

const ActivationFunction activationLogisticSigmoid = ActivationFunction(
    ActivationFunctionType.logistic, -1.0, 1.0,
    func: logisticFunc, derivative: logisticDeriv);

double leluFunc(double x) {
  if (x > 4) return 1 + 0.25 * x;
  if (x > -2)
    return 0.5 * x;
  return 0.0625 * x - 0.875;
}
double leluDeriv(double x) {
  if (x > 4) return 0.25;
  if (x > -2)
    return 0.5;
  return 0.0625;
}

const ActivationFunction activationLELU = ActivationFunction(
    ActivationFunctionType.lelu, double.negativeInfinity, double.infinity,
    func: leluFunc, derivative: leluDeriv);

final mapActivationFunction = <ActivationFunctionType, ActivationFunction>{
  ActivationFunctionType.abs: activationAbsSigmoid,
  ActivationFunctionType.logistic: activationLogisticSigmoid,
  ActivationFunctionType.tanh: activationTanh,
  ActivationFunctionType.bell: activationBell,
  ActivationFunctionType.gelu: activationGELU,
  ActivationFunctionType.lelu: activationLELU,
};

var activationTypeFromString = Map.fromEntries(
    ActivationFunctionType.values.map((e) => MapEntry(e.toString(), e)));
