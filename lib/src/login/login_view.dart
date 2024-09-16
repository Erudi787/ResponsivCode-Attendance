import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rts_locator/src/login/login_controller.dart';
import 'package:rts_locator/src/login/login_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  static const routeName = '/login';

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginController _loginController =
      Get.put(LoginController(LoginService()));

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  bool passwordObscured = true;

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.grey.shade200,
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Container(
          height: height - height * 0.120625,
          width: width,
          decoration: BoxDecoration(color: Colors.grey.shade200),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: height * 0.0265375),
                child: Image.asset(
                  "assets/background/rafiki.png",
                  fit: BoxFit.cover,
                ),
              ),
              Flexible(
                child: Container(
                  width: width,
                  decoration: const BoxDecoration(
                      color: Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      )),
                  child: Padding(
                    padding: EdgeInsets.only(
                        left: width * 0.06,
                        top: height * 0.05669375,
                        right: width * 0.06,
                        bottom: height * 0.05669375),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    EdgeInsets.only(bottom: height * 0.024125),
                                child: Text(
                                  "Login",
                                  style: GoogleFonts.poppins(
                                      fontSize: height * 0.0217125,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.1),
                                ),
                              ),
                              Padding(
                                padding:
                                    EdgeInsets.only(bottom: height * 0.02895),
                                child: Row(
                                  children: [
                                    Padding(
                                      padding:
                                          EdgeInsets.only(right: width * 0.025),
                                      child: const Icon(
                                        Icons.person_2_outlined,
                                        color: Color(0xFFF9A620),
                                      ),
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _usernameController,
                                        style: GoogleFonts.poppins(
                                            fontSize: height * 0.0168875,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black),
                                        decoration: InputDecoration(
                                          label: Text(
                                            "Username",
                                            style: GoogleFonts.poppins(
                                                fontSize: height * 0.0120625,
                                                fontWeight: FontWeight.w400,
                                                color: const Color(0xFFADB2BB)),
                                          ),
                                          focusedBorder:
                                              const UnderlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Color(0xFFCC0F2B),
                                            ),
                                          ),
                                        ),
                                        validator: (value) {
                                          value =
                                              _usernameController.text.trim();
                                          if (value.isEmpty) {
                                            return 'Please enter your username';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(right: 10),
                                    child: Icon(
                                      Icons.lock_outline_rounded,
                                      color: Color(0xFFF9A620),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      obscureText: passwordObscured,
                                      controller: _passwordController,
                                      style: GoogleFonts.poppins(
                                          fontSize: height * 0.0168875,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black),
                                      decoration: InputDecoration(
                                        label: Text(
                                          "Password",
                                          style: GoogleFonts.poppins(
                                              fontSize: height * 0.0120625,
                                              fontWeight: FontWeight.w400,
                                              color: const Color(0xFFADB2BB)),
                                        ),
                                        focusedBorder:
                                            const UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Color(0xFFCC0F2B),
                                          ),
                                        ),
                                        suffixIcon: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              passwordObscured =
                                                  !passwordObscured;
                                            });
                                          },
                                          icon: passwordObscured
                                              ? const Icon(Icons.visibility)
                                              : const Icon(
                                                  Icons.visibility_off),
                                        ),
                                      ),
                                      validator: (value) {
                                        value = _passwordController.text.trim();
                                        if (value.isEmpty) {
                                          return 'Please enter your password';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                if (_formKey.currentState!.validate()) {
                                  await _loginController.login(
                                      username: _usernameController.text.trim(),
                                      password:
                                          _passwordController.text.trim());
                                }
                              },
                              child: Obx(() {
                                return _loginController.isLoading.value
                                    ? Container(
                                        decoration: BoxDecoration(
                                            color: Colors.grey,
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                              left: width * 0.355,
                                              top: height * 0.01809375,
                                              right: width * 0.355,
                                              bottom: height * 0.01809375),
                                          child: Text(
                                            "LOGIN",
                                            style: GoogleFonts.poppins(
                                                fontSize: height * 0.0193,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.1,
                                                color: Colors.white),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFCC0F2B),
                                                Color(0xFFF9A620)
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                              left: width * 0.355,
                                              top: height * 0.01809375,
                                              right: width * 0.355,
                                              bottom: height * 0.01809375),
                                          child: Text(
                                            "LOGIN",
                                            style: GoogleFonts.poppins(
                                                fontSize: height * 0.0193,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.1,
                                                color: Colors.white),
                                          ),
                                        ),
                                      );
                              }),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
