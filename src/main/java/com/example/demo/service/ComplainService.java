package com.example.demo.service;

import com.example.demo.dto.ComplainToPost;
import com.example.demo.model.Client;
import com.example.demo.model.Complain;
import com.example.demo.model.Mark;
import com.example.demo.repository.ComplainRepository;
import com.example.demo.repository.MarkRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class ComplainService {
    @Autowired
    ComplainRepository complainRepository;
    @Autowired
    ClientService clientService;
    @Autowired
    MarkRepository markRepository;

    public Complain save(ComplainToPost complainToPost){
        Optional<Mark> mark = markRepository.findByLatitude(complainToPost.getLatitude());
        Client client = clientService.findClientByEmail(complainToPost.getEmail());
        Complain complain = new Complain(null, complainToPost.getComplain(), mark.get(), client);
        return complainRepository.save(complain);
    }
}
