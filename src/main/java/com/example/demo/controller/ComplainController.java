package com.example.demo.controller;

import com.example.demo.dto.ComplainToPost;
import com.example.demo.service.ComplainService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Optional;

@RestController
@RequestMapping("/complain")
public class ComplainController {
    @Autowired
    ComplainService complainService;

    @PostMapping
    public HttpStatus save(@RequestBody ComplainToPost complainToPost){
        System.out.println(complainToPost);
        complainService.save(complainToPost);
        return HttpStatus.CREATED;
    }
}
